// Arranque local de FindMyPet sin instalar PostgreSQL.
// Usa PGlite (PostgreSQL compilado a WebAssembly) como servidor de base de datos local.
//   node scripts/local.js           -> base de datos + API + frontend (http://localhost:5173)
//   node scripts/local.js --probar  -> ejecuta las pruebas automáticas con una base de datos temporal
//   node scripts/local.js --reiniciar -> borra los datos locales y vuelve a cargar la demostración
const { spawn } = require('child_process');
const fs = require('fs');
const net = require('net');
const path = require('path');

const RAIZ = path.join(__dirname, '..');
const SERVER = path.join(RAIZ, 'server');
const CLIENT = path.join(RAIZ, 'client');
const PGLITE = path.join(SERVER, 'node_modules', '@electric-sql', 'pglite-socket', 'dist', 'scripts', 'server.js');
const DATOS = path.join(SERVER, '.datos-locales');
const esWindows = process.platform === 'win32';
const procesos = [];

function iniciar(nombre, comando, args, opciones = {}) {
  const p = spawn(comando, args, { stdio: 'inherit', shell: esWindows && comando === 'npm', ...opciones });
  p.on('exit', (codigo) => {
    if (opciones.esperarFin) return;
    console.log(`\n[${nombre}] terminó (código ${codigo}). Cerrando todo…`);
    cerrar(codigo || 0);
  });
  procesos.push(p);
  return p;
}

function ejecutar(comando, args, opciones) {
  return new Promise((resolve, reject) => {
    const p = spawn(comando, args, { stdio: 'inherit', shell: esWindows && comando === 'npm', ...opciones });
    p.on('exit', (c) => (c === 0 ? resolve() : reject(new Error(`${comando} ${args.join(' ')} terminó con código ${c}`))));
  });
}

function esperarPuerto(puerto, intentos = 60) {
  return new Promise((resolve, reject) => {
    const probar = (n) => {
      const s = net.connect(puerto, '127.0.0.1');
      s.on('connect', () => { s.end(); resolve(); });
      s.on('error', () => (n <= 0 ? reject(new Error(`El puerto ${puerto} no respondió`)) : setTimeout(() => probar(n - 1), 500)));
    };
    probar(intentos);
  });
}

function cerrar(codigo = 0) {
  for (const p of procesos) { try { p.kill(); } catch { /* ya cerró */ } }
  process.exit(codigo);
}
process.on('SIGINT', () => cerrar(0));

async function main() {
  if (!fs.existsSync(PGLITE)) {
    console.error('Faltan dependencias. Ejecute primero: cd server && npm install');
    process.exit(1);
  }
  const probar = process.argv.includes('--probar');
  const puerto = probar ? 5434 : 5433;
  if (process.argv.includes('--reiniciar')) fs.rmSync(DATOS, { recursive: true, force: true });
  const nueva = !fs.existsSync(DATOS);

  console.log(`\n▶ Iniciando base de datos local (PGlite) en el puerto ${puerto}…`);
  iniciar('base de datos', process.execPath, [PGLITE, '-d', probar ? 'memory://' : DATOS, '-p', String(puerto), '-m', '10']);
  await esperarPuerto(puerto);
  const url = `postgresql://postgres:postgres@127.0.0.1:${puerto}/postgres`;

  if (probar) {
    console.log('\n▶ Ejecutando las pruebas automáticas…\n');
    try {
      await ejecutar('npm', ['test'], { cwd: SERVER, env: { ...process.env, TEST_DATABASE_URL: url } });
      cerrar(0);
    } catch {
      cerrar(1);
    }
    return;
  }

  const env = {
    ...process.env,
    DATABASE_URL: url,
    JWT_SECRET: process.env.JWT_SECRET || 'secreto-local-de-desarrollo-findmypet',
    PORT: '4000',
    FRONTEND_URL: 'http://localhost:5173',
    CORS_ORIGIN: 'http://localhost:5173',
  };
  await ejecutar(process.execPath, ['db/migrar.js'], { cwd: SERVER, env });
  if (nueva) {
    console.log('\n▶ Primera ejecución: cargando datos de demostración…');
    await ejecutar(process.execPath, ['db/seed.js'], { cwd: SERVER, env });
  }

  console.log('\n▶ Iniciando la API en http://localhost:4000 …');
  iniciar('API', process.execPath, ['src/index.js'], { cwd: SERVER, env });
  await esperarPuerto(4000);

  console.log('\n▶ Iniciando la aplicación web…');
  iniciar('web', 'npm', ['run', 'dev', '--', '--open'], { cwd: CLIENT });
  console.log('\n✔ FindMyPet está corriendo en http://localhost:5173');
  console.log('  Cuentas de prueba (contraseña Clave1234): admin@findmypet.com, ana@findmypet.com, luis@findmypet.com, huellitas@findmypet.com');
  console.log('  Para detener todo, cierre esta ventana o presione Ctrl + C.\n');
}

main().catch((e) => { console.error(`\n✖ ${e.message}`); cerrar(1); });
