const { app, request, limpiarBD, cerrarBD, crearUsuario, conToken } = require('./ayudas');

let refugio;
let ana;
let luis;
let idSolicitud;

beforeAll(async () => {
  await limpiarBD();
  refugio = await crearUsuario({ correo: 'refugio@test.com', rol: 2, nombres: 'Patitas' });
  ana = await crearUsuario({ correo: 'ana@test.com', nombres: 'Ana' });
  luis = await crearUsuario({ correo: 'luis@test.com', nombres: 'Luis' });
  const s = await request(app).post('/api/donaciones').set(conToken(refugio.token))
    .send({ titulo: 'Balanceado para cachorros', descripcion: 'Necesitamos sacos de balanceado para cachorros' });
  idSolicitud = s.body.id;
});
afterAll(cerrarBD);

describe('RF-25: el donante corrige o elimina su aporte', () => {
  let idAporte;

  test('registra un aporte y lo ve en "mis aportes"', async () => {
    const res = await request(app).post(`/api/donaciones/${idSolicitud}/aportes`).set(conToken(ana.token)).send({ monto: 500 });
    expect(res.status).toBe(201);
    idAporte = res.body.id;
    const mios = await request(app).get('/api/donaciones/mis-aportes').set(conToken(ana.token));
    expect(mios.body).toHaveLength(1);
    expect(mios.body[0]).toMatchObject({ id: idAporte, monto: 500, editable: true, titulo: 'Balanceado para cachorros' });
  });

  test('cambia el monto equivocado o lo quita dejando solo insumos', async () => {
    const res = await request(app).patch(`/api/donaciones/aportes/${idAporte}`).set(conToken(ana.token)).send({ monto: '5.50', detalle: '' });
    expect(res.status).toBe(200);
    expect(res.body.monto).toBe(5.5);
    const sinMonto = await request(app).patch(`/api/donaciones/aportes/${idAporte}`).set(conToken(ana.token)).send({ monto: '', detalle: '1 saco de 15 kg' });
    expect(sinMonto.status).toBe(200);
    expect(sinMonto.body).toMatchObject({ monto: null, detalle: '1 saco de 15 kg' });
  });

  test('no permite dejar el aporte vacío ni un monto inválido', async () => {
    const vacio = await request(app).patch(`/api/donaciones/aportes/${idAporte}`).set(conToken(ana.token)).send({ monto: '', detalle: '' });
    expect(vacio.status).toBe(400);
    const negativo = await request(app).patch(`/api/donaciones/aportes/${idAporte}`).set(conToken(ana.token)).send({ monto: -3 });
    expect(negativo.status).toBe(400);
  });

  test('otro usuario no puede editar ni eliminar el aporte', async () => {
    expect((await request(app).patch(`/api/donaciones/aportes/${idAporte}`).set(conToken(luis.token)).send({ monto: 1 })).status).toBe(404);
    expect((await request(app).delete(`/api/donaciones/aportes/${idAporte}`).set(conToken(luis.token))).status).toBe(404);
  });

  test('con la solicitud cerrada el aporte ya no se modifica', async () => {
    await request(app).patch(`/api/donaciones/${idSolicitud}`).set(conToken(refugio.token)).send({ idEstado: 2 });
    expect((await request(app).patch(`/api/donaciones/aportes/${idAporte}`).set(conToken(ana.token)).send({ monto: 2 })).status).toBe(400);
    const mios = await request(app).get('/api/donaciones/mis-aportes').set(conToken(ana.token));
    expect(mios.body[0].editable).toBe(false);
    await request(app).patch(`/api/donaciones/${idSolicitud}`).set(conToken(refugio.token)).send({ idEstado: 1 });
  });

  test('elimina el aporte y deja de contar en la solicitud', async () => {
    const res = await request(app).delete(`/api/donaciones/aportes/${idAporte}`).set(conToken(ana.token));
    expect(res.status).toBe(204);
    expect((await request(app).get('/api/donaciones/mis-aportes').set(conToken(ana.token))).body).toHaveLength(0);
    const abiertas = await request(app).get('/api/donaciones');
    expect(abiertas.body.find((s) => s.id === idSolicitud).aportes).toBe(0);
  });
});

describe('Catálogo de ubicaciones', () => {
  test('incluye las 24 provincias y al menos 3 sectores por cantón', async () => {
    const { body } = await request(app).get('/api/catalogos');
    expect(body.provincias).toHaveLength(24);
    for (const c of body.cantones) {
      expect(body.sectores.filter((s) => s.idCanton === c.id).length).toBeGreaterThanOrEqual(3);
    }
  });
});
