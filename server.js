import express from "express";
import path from "path";
import { fileURLToPath } from "url";
import engine from "ejs-mate";
import session from "express-session";
// opcional para depois: import mysql from "mysql2/promise";
// import bcrypt from "bcryptjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname  = path.dirname(__filename);

const app  = express();
const PORT = process.env.PORT || 8082;

/* ----------------------- View engine (ejs-mate) ----------------------- */
app.engine("ejs", engine);
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

/* ---------------------------- Middlewares ----------------------------- */
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use("/static",  express.static(path.join(__dirname, "public")));
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

/* ------------------------------- Sessão ------------------------------- */
app.use(
  session({
    name: "plano.sid",
    secret: process.env.SESSION_SECRET || "dev-secret-planograma",
    resave: false,
    saveUninitialized: false,
    cookie: {
      httpOnly: true,
      sameSite: "lax",
      maxAge: 1000 * 60 * 60 * 8, // 8h
    },
  })
);

/* -------------------- Variáveis disponíveis no EJS -------------------- */
app.use((req, res, next) => {
  res.locals.user  = req.session.user || null;
  res.locals.title = "Planograma v2";
  next();
});

/* ---------------------------- Helpers simples ------------------------- */
function requireAuth(req, res, next) {
  if (!req.session.user) return res.redirect("/login");
  next();
}

/* -------------------------------- Rotas ------------------------------- */

// Home (somente logado)
app.get("/", requireAuth, (req, res) => {
  res.render("home", {
    // você pode criar views/home.ejs depois; por agora,
    // vamos usar o layout e um conteúdo mínimo inline:
    // se não existir views/home.ejs, descomente o render abaixo:
    // string template:
    // dica: crie um views/home.ejs e mude aqui para res.render("home")
    // mas para não travar, vamos renderizar uma página simples com layout:
  });
});

// Login (GET)
app.get("/login", (req, res) => {
  if (req.session.user) return res.redirect("/");
  res.render("login", { error: null });
});

// Login (POST) – por enquanto permite qualquer usuário/senha (modo dev)
// Depois você troca pelo SELECT no MySQL + bcrypt.
app.post("/login", (req, res) => {
  const { username, password } = req.body;

  // validação mínima
  if (!username || !password) {
    return res.status(400).render("login", { error: "Informe usuário e senha." });
  }

  // MODO DEV: autentica sempre
  req.session.user = { id: 1, username };
  return res.redirect("/");
});

// Logout
app.get("/logout", (req, res) => {
  req.session.destroy(() => {
    res.clearCookie("plano.sid");
    res.redirect("/login");
  });
});

/* --------------------------- Fallback 404 ----------------------------- */
app.use((req, res) => {
  res.status(404).render("login", { error: "Página não encontrada." });
});

/* ---------------------------- Start server ---------------------------- */
app.listen(PORT, () => {
  console.log(`✔ Planograma v2 rodando em :${PORT}`);
});
