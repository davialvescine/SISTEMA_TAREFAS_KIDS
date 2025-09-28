# 🚀 Sistema de Tarefas Kids - Setup Inicial

## Passo 1: Configurar Projeto Flutter

```bash
# Criar o projeto
flutter create sistema_tarefas_kids
cd sistema_tarefas_kids

# Instalar dependências
flutter pub add supabase_flutter
flutter pub add provider
flutter pub add google_fonts
flutter pub add smooth_page_indicator
flutter pub add flutter_animate
flutter pub add lottie
flutter pub add shared_preferences
flutter pub add intl
flutter pub add flutter_svg
flutter pub add cached_network_image

# Verificar se tudo está ok
flutter doctor
```

## Passo 2: Estrutura de Pastas

Crie a seguinte estrutura no diretório `lib/`:

```
lib/
├── core/
│   ├── constants/
│   │   └── supabase_constants.dart
│   └── providers/
│       └── auth_provider.dart
├── presentation/
│   └── screens/
│       ├── auth/
│       │   ├── login_screen.dart
│       │   └── register_screen.dart
│       ├── home/
│       │   └── dashboard_screen.dart
│       ├── onboarding/
│       │   └── onboarding_screen.dart
│       └── splash/
│           └── splash_screen.dart
├── app.dart
└── main.dart
```

## Passo 3: Configurar Supabase

### 3.1 Criar conta e projeto no Supabase

1. Acesse [https://supabase.com](https://supabase.com)
2. Crie uma conta gratuita
3. Crie um novo projeto
4. Anote a **Project URL** e **Anon Key**

### 3.2 Criar as tabelas no banco de dados

Execute o seguinte SQL no SQL Editor do Supabase:

```sql
-- Tabela de usuários (pais)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  subscription_type TEXT DEFAULT 'free',
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Tabela de crianças
CREATE TABLE children (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  avatar_url TEXT,
  color TEXT NOT NULL,
  birth_date DATE,
  current_points INT DEFAULT 0,
  total_points INT DEFAULT 0,
  stars INT DEFAULT 0,
  real_money DECIMAL(10,2) DEFAULT 0,
  level INT DEFAULT 1,
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Habilitar RLS (Row Level Security)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE children ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para users
CREATE POLICY "Users can view own profile" 
  ON users FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
  ON users FOR UPDATE 
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
  ON users FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Políticas de segurança para children
CREATE POLICY "Users can view own children" 
  ON children FOR SELECT 
  USING (user_id = auth.uid());

CREATE POLICY "Users can create own children" 
  ON children FOR INSERT 
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own children" 
  ON children FOR UPDATE 
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own children" 
  ON children FOR DELETE 
  USING (user_id = auth.uid());
```

### 3.3 Configurar autenticação

No painel do Supabase:

1. Vá para **Authentication** → **Providers**
2. Habilite **Email** provider
3. Configure as mensagens de email se desejar

## Passo 4: Atualizar Credenciais

No arquivo `lib/core/constants/supabase_constants.dart`:

```dart
class SupabaseConstants {
  static const String url = 'SEU_SUPABASE_PROJECT_URL_AQUI';
  static const String anonKey = 'SEU_SUPABASE_ANON_KEY_AQUI';
}
```

## Passo 5: Criar Assets (Opcional)

Crie as seguintes pastas na raiz do projeto:

```
assets/
├── images/
├── animations/
├── icons/
└── fonts/
    ├── Poppins-Regular.ttf
    ├── Poppins-Medium.ttf
    ├── Poppins-SemiBold.ttf
    └── Poppins-Bold.ttf
```

Baixe as fontes Poppins em: [Google Fonts](https://fonts.google.com/specimen/Poppins)

## Passo 6: Executar o App

```bash
# Para debug
flutter run

# Para release (Android)
flutter build apk --release

# Para release (iOS)
flutter build ios --release
```

## 📱 Fluxo do App

1. **Primeira vez**: Splash → Onboarding → Login/Cadastro → Dashboard
2. **Já logado**: Splash → Dashboard
3. **Não logado**: Splash → Login

## 🎨 Funcionalidades Implementadas

✅ Tela de Splash animada  
✅ Onboarding com 4 slides  
✅ Login com email/senha  
✅ Cadastro de novos usuários  
✅ Recuperação de senha  
✅ Dashboard principal  
✅ Adicionar crianças  
✅ Visualizar crianças cadastradas  
✅ Sistema de cores personalizadas  
✅ Animações fluidas  
✅ Logout  

## 🚧 Próximas Funcionalidades

- [ ] Sistema de tarefas
- [ ] Marcar tarefas concluídas
- [ ] Sistema de pontuação
- [ ] Conversão de pontos
- [ ] Recompensas
- [ ] Histórico
- [ ] Gráficos e relatórios
- [ ] Notificações
- [ ] Configurações avançadas

## 🐛 Troubleshooting

### Erro de conexão com Supabase
- Verifique se as credenciais estão corretas
- Confirme se o projeto está ativo no Supabase
- Teste a conexão no navegador

### Build falha no iOS
- Execute `cd ios && pod install`
- Abra no Xcode e configure signing

### Build falha no Android
- Verifique minSdkVersion (mínimo 21)
- Configure o gradle.properties

## 📞 Suporte

Em caso de dúvidas, consulte:
- [Documentação Flutter](https://docs.flutter.dev/)
- [Documentação Supabase](https://supabase.com/docs)
- [Stack Overflow](https://stackoverflow.com/)

## 📄 Licença

Este projeto é para fins educacionais.# SISTEMA_TAREFAS_KIDS
