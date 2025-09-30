-- ===========================================================
-- SCRIPT COMPLETO PARA CONFIGURAR O BANCO DE DADOS SUPABASE
-- ===========================================================

-- 1. CRIAR TABELAS SE NÃO EXISTIREM
-- ===========================================================

-- Tabela de usuários (estende auth.users)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255),
    email VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tabela de crianças
CREATE TABLE IF NOT EXISTS children (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    color VARCHAR(50) DEFAULT 'purple',
    birth_date DATE,
    current_points INTEGER DEFAULT 0,
    total_points INTEGER DEFAULT 0,
    stars INTEGER DEFAULT 0,
    real_money DECIMAL(10,2) DEFAULT 0.00,
    level INTEGER DEFAULT 1,
    settings JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tabela de tarefas
CREATE TABLE IF NOT EXISTS tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    points INTEGER NOT NULL DEFAULT 10,
    recurrence VARCHAR(50) DEFAULT 'daily',
    category VARCHAR(100),
    difficulty VARCHAR(50) DEFAULT 'easy',
    icon VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tabela de atividades (histórico de tarefas completadas)
CREATE TABLE IF NOT EXISTS activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    child_id UUID REFERENCES children(id) ON DELETE CASCADE NOT NULL,
    task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
    task_name VARCHAR(255) NOT NULL,
    points INTEGER NOT NULL,
    type VARCHAR(50) DEFAULT 'positive',
    description TEXT,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tabela de recompensas
CREATE TABLE IF NOT EXISTS rewards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    cost_type VARCHAR(50) NOT NULL, -- 'points', 'stars', 'money'
    cost INTEGER NOT NULL,
    icon VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tabela de resgates
CREATE TABLE IF NOT EXISTS redemptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    child_id UUID REFERENCES children(id) ON DELETE CASCADE NOT NULL,
    reward_id UUID REFERENCES rewards(id) ON DELETE SET NULL,
    reward_name VARCHAR(255) NOT NULL,
    cost_type VARCHAR(50) NOT NULL,
    cost INTEGER NOT NULL,
    redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. CRIAR ÍNDICES PARA MELHOR PERFORMANCE
-- ===========================================================

CREATE INDEX IF NOT EXISTS idx_children_user_id ON children(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_child_id ON activities(child_id);
CREATE INDEX IF NOT EXISTS idx_rewards_user_id ON rewards(user_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_child_id ON redemptions(child_id);

-- 3. CRIAR FUNÇÕES E TRIGGERS
-- ===========================================================

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar trigger nas tabelas que têm updated_at
DROP TRIGGER IF EXISTS update_children_updated_at ON children;
CREATE TRIGGER update_children_updated_at BEFORE UPDATE ON children
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_rewards_updated_at ON rewards;
CREATE TRIGGER update_rewards_updated_at BEFORE UPDATE ON rewards
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Função para atualizar pontos da criança quando uma atividade é inserida
CREATE OR REPLACE FUNCTION update_child_points()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.type = 'positive' THEN
        UPDATE children
        SET
            current_points = current_points + NEW.points,
            total_points = total_points + NEW.points
        WHERE id = NEW.child_id;
    ELSIF NEW.type = 'negative' THEN
        UPDATE children
        SET current_points = GREATEST(0, current_points - NEW.points)
        WHERE id = NEW.child_id;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para atualizar pontos automaticamente
DROP TRIGGER IF EXISTS update_points_on_activity ON activities;
CREATE TRIGGER update_points_on_activity AFTER INSERT ON activities
    FOR EACH ROW EXECUTE PROCEDURE update_child_points();

-- 4. DESABILITAR RLS TEMPORARIAMENTE (PARA TESTE)
-- ===========================================================

ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE children DISABLE ROW LEVEL SECURITY;
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE activities DISABLE ROW LEVEL SECURITY;
ALTER TABLE rewards DISABLE ROW LEVEL SECURITY;
ALTER TABLE redemptions DISABLE ROW LEVEL SECURITY;

-- 5. CONFIGURAR RLS BÁSICO (COMENTADO PARA TESTES)
-- ===========================================================
-- Quando quiser habilitar RLS, descomente as linhas abaixo:

-- ALTER TABLE children ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE redemptions ENABLE ROW LEVEL SECURITY;

-- -- Políticas para children
-- CREATE POLICY "Users can view own children" ON children
--     FOR SELECT USING (auth.uid() = user_id);
-- CREATE POLICY "Users can insert own children" ON children
--     FOR INSERT WITH CHECK (auth.uid() = user_id);
-- CREATE POLICY "Users can update own children" ON children
--     FOR UPDATE USING (auth.uid() = user_id);
-- CREATE POLICY "Users can delete own children" ON children
--     FOR DELETE USING (auth.uid() = user_id);

-- -- Políticas para tasks
-- CREATE POLICY "Users can view own tasks" ON tasks
--     FOR SELECT USING (auth.uid() = user_id);
-- CREATE POLICY "Users can insert own tasks" ON tasks
--     FOR INSERT WITH CHECK (auth.uid() = user_id);
-- CREATE POLICY "Users can update own tasks" ON tasks
--     FOR UPDATE USING (auth.uid() = user_id);
-- CREATE POLICY "Users can delete own tasks" ON tasks
--     FOR DELETE USING (auth.uid() = user_id);

-- -- Políticas para activities
-- CREATE POLICY "Users can view activities of own children" ON activities
--     FOR SELECT USING (
--         EXISTS (
--             SELECT 1 FROM children
--             WHERE children.id = activities.child_id
--             AND children.user_id = auth.uid()
--         )
--     );
-- CREATE POLICY "Users can insert activities for own children" ON activities
--     FOR INSERT WITH CHECK (
--         EXISTS (
--             SELECT 1 FROM children
--             WHERE children.id = activities.child_id
--             AND children.user_id = auth.uid()
--         )
--     );

-- 6. INSERIR DADOS DE EXEMPLO (OPCIONAL)
-- ===========================================================
-- Descomente se quiser criar dados de teste

-- INSERT INTO tasks (user_id, title, description, points, category, difficulty, icon)
-- VALUES
--     (auth.uid(), 'Escovar os dentes', 'Escovar os dentes após as refeições', 5, 'Higiene', 'easy', '🦷'),
--     (auth.uid(), 'Arrumar a cama', 'Arrumar a cama ao acordar', 5, 'Organização', 'easy', '🛏️'),
--     (auth.uid(), 'Fazer lição de casa', 'Completar toda a lição de casa', 15, 'Estudos', 'medium', '📚'),
--     (auth.uid(), 'Guardar brinquedos', 'Organizar todos os brinquedos', 10, 'Organização', 'easy', '🧸'),
--     (auth.uid(), 'Ajudar na cozinha', 'Ajudar a preparar o jantar', 20, 'Ajuda', 'hard', '👨‍🍳');

-- 7. VERIFICAR SE TUDO FOI CRIADO
-- ===========================================================
-- Execute estas queries para verificar:
-- SELECT * FROM children WHERE user_id = auth.uid();
-- SELECT * FROM tasks WHERE user_id = auth.uid();