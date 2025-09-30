-- ====================================================
-- CORREÇÃO URGENTE - TABELA CHILDREN
-- ====================================================

-- 1. Verificar se a tabela existe
SELECT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'children'
);

-- 2. Se não existir, criar a tabela
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

-- 3. Criar índice se não existir
CREATE INDEX IF NOT EXISTS idx_children_user_id ON children(user_id);

-- 4. DESABILITAR RLS TEMPORARIAMENTE PARA TESTE
ALTER TABLE children DISABLE ROW LEVEL SECURITY;

-- 5. Remover todas as políticas existentes
DROP POLICY IF EXISTS "Users can view own children" ON children;
DROP POLICY IF EXISTS "Users can insert own children" ON children;
DROP POLICY IF EXISTS "Users can update own children" ON children;
DROP POLICY IF EXISTS "Users can delete own children" ON children;

-- 6. Verificar se a tabela está acessível
SELECT * FROM children LIMIT 1;

-- 7. Teste de inserção (substitua o UUID por um ID de usuário real)
-- INSERT INTO children (user_id, name, color)
-- VALUES ('seu-user-id-aqui', 'Teste', 'blue');

-- ====================================================
-- DEPOIS DE TESTAR E CONFIRMAR QUE FUNCIONA
-- Execute o script abaixo para reabilitar RLS
-- ====================================================

/*
-- Reabilitar RLS
ALTER TABLE children ENABLE ROW LEVEL SECURITY;

-- Criar políticas simples
CREATE POLICY "Enable all for authenticated users" ON children
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
*/