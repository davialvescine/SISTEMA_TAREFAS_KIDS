-- ===========================================================
-- CONFIGURAÇÃO FINAL DO BANCO DE DADOS SUPABASE
-- Sistema de Tarefas Kids - Versão Atualizada
-- ===========================================================

-- 1. LIMPAR ESTRUTURA EXISTENTE (SE NECESSÁRIO)
-- ===========================================================
DROP TABLE IF EXISTS redemptions CASCADE;
DROP TABLE IF EXISTS rewards CASCADE;
DROP TABLE IF EXISTS activities CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS children CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 2. CRIAR ESTRUTURA DE TABELAS
-- ===========================================================

-- Tabela de usuários (informações adicionais)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255),
    email VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    subscription_plan VARCHAR(50) DEFAULT 'free',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tabela de crianças
CREATE TABLE children (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    color VARCHAR(50) DEFAULT 'purple' CHECK (color IN ('purple', 'blue', 'green', 'orange', 'pink', 'red')),
    birth_date DATE,
    current_points INTEGER DEFAULT 0 CHECK (current_points >= 0),
    total_points INTEGER DEFAULT 0 CHECK (total_points >= 0),
    stars INTEGER DEFAULT 0 CHECK (stars >= 0),
    real_money DECIMAL(10,2) DEFAULT 0.00 CHECK (real_money >= 0),
    level INTEGER DEFAULT 1 CHECK (level >= 1),
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tabela de tarefas
CREATE TABLE tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    points INTEGER NOT NULL DEFAULT 10 CHECK (points > 0),
    recurrence VARCHAR(50) DEFAULT 'daily' CHECK (recurrence IN ('daily', 'weekly', 'monthly', 'unlimited')),
    recurrence_limit INTEGER,
    category VARCHAR(100),
    difficulty VARCHAR(50) DEFAULT 'easy' CHECK (difficulty IN ('easy', 'medium', 'hard')),
    icon VARCHAR(50),
    color VARCHAR(7),
    is_active BOOLEAN DEFAULT true,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tabela de atividades (histórico)
CREATE TABLE activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    child_id UUID REFERENCES children(id) ON DELETE CASCADE NOT NULL,
    task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
    task_name VARCHAR(255) NOT NULL,
    points INTEGER NOT NULL,
    type VARCHAR(50) DEFAULT 'positive' CHECK (type IN ('positive', 'negative', 'neutral')),
    description TEXT,
    notes TEXT,
    photo_url TEXT,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tabela de recompensas
CREATE TABLE rewards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    cost_type VARCHAR(50) NOT NULL CHECK (cost_type IN ('points', 'stars', 'money')),
    cost INTEGER NOT NULL CHECK (cost > 0),
    icon VARCHAR(50),
    color VARCHAR(7),
    is_active BOOLEAN DEFAULT true,
    stock_quantity INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tabela de resgates
CREATE TABLE redemptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    child_id UUID REFERENCES children(id) ON DELETE CASCADE NOT NULL,
    reward_id UUID REFERENCES rewards(id) ON DELETE SET NULL,
    reward_name VARCHAR(255) NOT NULL,
    cost_type VARCHAR(50) NOT NULL,
    cost INTEGER NOT NULL,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'delivered', 'cancelled')),
    notes TEXT,
    redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    processed_at TIMESTAMP WITH TIME ZONE
);

-- 3. CRIAR ÍNDICES PARA PERFORMANCE
-- ===========================================================
CREATE INDEX idx_children_user_id ON children(user_id);
CREATE INDEX idx_children_is_active ON children(is_active);
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_is_active ON tasks(is_active);
CREATE INDEX idx_activities_child_id ON activities(child_id);
CREATE INDEX idx_activities_completed_at ON activities(completed_at DESC);
CREATE INDEX idx_rewards_user_id ON rewards(user_id);
CREATE INDEX idx_rewards_is_active ON rewards(is_active);
CREATE INDEX idx_redemptions_child_id ON redemptions(child_id);
CREATE INDEX idx_redemptions_status ON redemptions(status);

-- 4. CRIAR FUNÇÕES AUXILIARES
-- ===========================================================

-- Função para atualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Função para atualizar pontos da criança
CREATE OR REPLACE FUNCTION update_child_points()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.type = 'positive' THEN
        UPDATE children
        SET
            current_points = current_points + NEW.points,
            total_points = total_points + NEW.points,
            level = CASE
                WHEN (total_points + NEW.points) < 100 THEN 1
                WHEN (total_points + NEW.points) < 250 THEN 2
                WHEN (total_points + NEW.points) < 500 THEN 3
                WHEN (total_points + NEW.points) < 1000 THEN 4
                WHEN (total_points + NEW.points) < 2000 THEN 5
                ELSE 6
            END
        WHERE id = NEW.child_id;
    ELSIF NEW.type = 'negative' THEN
        UPDATE children
        SET current_points = GREATEST(0, current_points - NEW.points)
        WHERE id = NEW.child_id;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Função para processar resgate
CREATE OR REPLACE FUNCTION process_redemption()
RETURNS TRIGGER AS $$
DECLARE
    child_record children%ROWTYPE;
BEGIN
    -- Buscar dados da criança
    SELECT * INTO child_record FROM children WHERE id = NEW.child_id;

    -- Verificar saldo
    IF NEW.cost_type = 'points' AND child_record.current_points < NEW.cost THEN
        RAISE EXCEPTION 'Pontos insuficientes';
    ELSIF NEW.cost_type = 'stars' AND child_record.stars < NEW.cost THEN
        RAISE EXCEPTION 'Estrelas insuficientes';
    ELSIF NEW.cost_type = 'money' AND child_record.real_money < NEW.cost THEN
        RAISE EXCEPTION 'Dinheiro insuficiente';
    END IF;

    -- Deduzir do saldo
    IF NEW.cost_type = 'points' THEN
        UPDATE children SET current_points = current_points - NEW.cost WHERE id = NEW.child_id;
    ELSIF NEW.cost_type = 'stars' THEN
        UPDATE children SET stars = stars - NEW.cost WHERE id = NEW.child_id;
    ELSIF NEW.cost_type = 'money' THEN
        UPDATE children SET real_money = real_money - NEW.cost WHERE id = NEW.child_id;
    END IF;

    RETURN NEW;
END;
$$ language 'plpgsql';

-- 5. CRIAR TRIGGERS
-- ===========================================================

-- Triggers para updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_children_updated_at BEFORE UPDATE ON children
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rewards_updated_at BEFORE UPDATE ON rewards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para atualizar pontos
CREATE TRIGGER update_points_on_activity AFTER INSERT ON activities
    FOR EACH ROW EXECUTE FUNCTION update_child_points();

-- Trigger para processar resgate
CREATE TRIGGER process_redemption_trigger BEFORE INSERT ON redemptions
    FOR EACH ROW EXECUTE FUNCTION process_redemption();

-- 6. CONFIGURAR ROW LEVEL SECURITY (RLS)
-- ===========================================================

-- Habilitar RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE children ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE redemptions ENABLE ROW LEVEL SECURITY;

-- Políticas para users
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Políticas para children
CREATE POLICY "Users can view own children" ON children
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own children" ON children
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own children" ON children
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own children" ON children
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas para tasks
CREATE POLICY "Users can view own tasks" ON tasks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tasks" ON tasks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tasks" ON tasks
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tasks" ON tasks
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas para activities
CREATE POLICY "Users can view activities of own children" ON activities
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM children
            WHERE children.id = activities.child_id
            AND children.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert activities for own children" ON activities
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM children
            WHERE children.id = activities.child_id
            AND children.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete activities of own children" ON activities
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM children
            WHERE children.id = activities.child_id
            AND children.user_id = auth.uid()
        )
    );

-- Políticas para rewards
CREATE POLICY "Users can view own rewards" ON rewards
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own rewards" ON rewards
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own rewards" ON rewards
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own rewards" ON rewards
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas para redemptions
CREATE POLICY "Users can view redemptions of own children" ON redemptions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM children
            WHERE children.id = redemptions.child_id
            AND children.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert redemptions for own children" ON redemptions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM children
            WHERE children.id = redemptions.child_id
            AND children.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update redemptions of own children" ON redemptions
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM children
            WHERE children.id = redemptions.child_id
            AND children.user_id = auth.uid()
        )
    );

-- 7. INSERIR DADOS DE EXEMPLO (OPCIONAL)
-- ===========================================================
-- Descomente se quiser criar tarefas padrão para novos usuários

/*
-- Função para criar tarefas padrão
CREATE OR REPLACE FUNCTION create_default_tasks()
RETURNS TRIGGER AS $$
BEGIN
    -- Tarefas de Higiene
    INSERT INTO tasks (user_id, title, description, points, category, difficulty, icon, color)
    VALUES
        (NEW.id, 'Escovar os dentes', 'Escovar os dentes após as refeições', 5, 'Higiene', 'easy', '🦷', '#4CAF50'),
        (NEW.id, 'Tomar banho', 'Tomar banho diariamente', 10, 'Higiene', 'easy', '🚿', '#2196F3'),
        (NEW.id, 'Lavar as mãos', 'Lavar as mãos antes das refeições', 3, 'Higiene', 'easy', '🧼', '#00BCD4');

    -- Tarefas de Organização
    INSERT INTO tasks (user_id, title, description, points, category, difficulty, icon, color)
    VALUES
        (NEW.id, 'Arrumar a cama', 'Arrumar a cama ao acordar', 5, 'Organização', 'easy', '🛏️', '#9C27B0'),
        (NEW.id, 'Guardar brinquedos', 'Organizar os brinquedos após brincar', 10, 'Organização', 'easy', '🧸', '#FF9800'),
        (NEW.id, 'Organizar mochila', 'Preparar mochila para escola', 8, 'Organização', 'medium', '🎒', '#795548');

    -- Tarefas de Estudos
    INSERT INTO tasks (user_id, title, description, points, category, difficulty, icon, color)
    VALUES
        (NEW.id, 'Fazer lição de casa', 'Completar toda a lição de casa', 20, 'Estudos', 'medium', '📚', '#F44336'),
        (NEW.id, 'Ler por 15 minutos', 'Ler um livro por 15 minutos', 15, 'Estudos', 'medium', '📖', '#E91E63'),
        (NEW.id, 'Estudar para prova', 'Revisar matéria para prova', 25, 'Estudos', 'hard', '📝', '#3F51B5');

    -- Tarefas de Ajuda
    INSERT INTO tasks (user_id, title, description, points, category, difficulty, icon, color)
    VALUES
        (NEW.id, 'Ajudar com a louça', 'Ajudar a lavar ou guardar louça', 15, 'Ajuda', 'medium', '🍽️', '#009688'),
        (NEW.id, 'Alimentar pet', 'Dar comida e água para o pet', 10, 'Ajuda', 'easy', '🐾', '#8BC34A'),
        (NEW.id, 'Regar plantas', 'Regar as plantas da casa', 8, 'Ajuda', 'easy', '🌱', '#CDDC39');

    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para criar tarefas padrão
CREATE TRIGGER create_default_tasks_for_new_user
AFTER INSERT ON users
    FOR EACH ROW EXECUTE FUNCTION create_default_tasks();
*/

-- 8. GRANT PERMISSIONS
-- ===========================================================
-- As permissões já são gerenciadas pelo RLS

-- FIM DO SCRIPT
-- ===========================================================
-- Execute este script no SQL Editor do Supabase
-- Após executar, teste criando um novo usuário e adicionando crianças