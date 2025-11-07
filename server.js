import 'dotenv/config';
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import session from 'express-session';
import mysql from 'mysql2/promise';
import bcrypt from 'bcryptjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname  = path.dirname(__filename);

const app  = express();
const PORT = process.env.PORT || 8081;

// DB pool
const pool = await mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'planouser',
  password: process.env.DB_PASS || 'senhaSegura123',
  database: process.env.DB_NAME || 'planograma_v2',
  waitForConnections: true,
  connectionLimit: 10,
});

// middlewares
app.use(express.urlencoded({ extended: true, limit: '25mb' }));
app.use(express.json());
app.use('/static', express.static(path.join(__dirname, 'public')));

// sessões
app.use(session({
  secret: process.env.SESSION_SECRET || 'trocar-por-uma-chave-forte',
  resave: false,
  saveUninitialized: false,
}));

// ejs
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// --- Helpers simples de auth
function ensureAuth(req, res, next){
  if (req.session.user) return next();
  res.redirect('/login');
}

// --- Rotas de login/logout
app.get('/login', (req,res) => {
  res.render('login', { error: null });
});

app.post('/login', async (req,res) => {
  const { email, senha } = req.body;
  try {
    const [rows] = await pool.query('SELECT * FROM usuarios WHERE email=? AND status="aprovado" LIMIT 1', [email]);
    if (!rows.length) return res.render('login', { error: 'Usuário não encontrado ou não aprovado.' });
    const u = rows[0];
    const ok = await bcrypt.compare(senha, u.senha_hash);
    if (!ok) return res.render('login', { error: 'Senha inválida.' });

    // permissões/loja padrão
    const [loj] = await pool.query(
      'SELECT l.* FROM usuarios_lojas ul JOIN lojas l ON l.id_loja=ul.id_loja WHERE ul.id_usuario=? ORDER BY l.nome',
      [u.id_usuario]
    );

    req.session.user = {
      id: u.id_usuario,
      nome: u.nome,
      email: u.email,
      perfil: u.perfil,
      lojas: loj,
      id_loja: u.id_loja_padrao || (loj[0]?.id_loja ?? null)
    };
    res.redirect('/');
  } catch (e) {
    console.error(e);
    res.render('login', { error: 'Erro ao autenticar.' });
  }
});

app.post('/logout', (req,res) => {
  req.session.destroy(() => res.redirect('/login'));
});

// troca de loja (apenas se tiver acesso)
app.post('/trocar-loja', ensureAuth, (req,res) => {
  const id = Number(req.body.id_loja);
  if (req.session.user.lojas?.some(l => l.id_loja === id)) {
    req.session.user.id_loja = id;
  }
  res.redirect('/');
});

// --- Home (placeholder)
app.get('/', ensureAuth, async (req,res) => {
  // Mostra só um oi e a loja atual; depois substituímos pelos cards/relatórios.
  res.render('index', { user: req.session.user });
});

// 404
app.use((req,res)=> res.status(404).send('404'));

// start
app.listen(PORT, () => console.log(`✔ Planograma v2 rodando em :${PORT}`));
