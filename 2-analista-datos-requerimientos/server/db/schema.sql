-- =====================================================================
-- FindMyPet · Esquema de base de datos (PostgreSQL 14+)
-- Basado en el Modelo de datos (sección 2.4 del Plan de Proyecto, Grupo 4)
-- Se ejecuta con: npm run db:migrate
-- =====================================================================

-- ---------- Catálogos ----------
CREATE TABLE IF NOT EXISTS rol (
  id_rol  INT PRIMARY KEY,
  nombre  VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS estado_cuenta (
  id_estado_cuenta INT PRIMARY KEY,
  nombre           VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS tipo_token (
  id_tipo_token INT PRIMARY KEY,
  nombre        VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS tipo_publicacion (
  id_tipo INT PRIMARY KEY,
  nombre  VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS estado_publicacion (
  id_estado INT PRIMARY KEY,
  id_tipo   INT NOT NULL REFERENCES tipo_publicacion(id_tipo),
  nombre    VARCHAR(20) NOT NULL,
  UNIQUE (id_tipo, nombre)
);

CREATE TABLE IF NOT EXISTS especie (
  id_especie INT PRIMARY KEY,
  nombre     VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS raza (
  id_raza    SERIAL PRIMARY KEY,
  id_especie INT NOT NULL REFERENCES especie(id_especie),
  nombre     VARCHAR(60) NOT NULL,
  UNIQUE (id_especie, nombre)
);

CREATE TABLE IF NOT EXISTS tamano (
  id_tamano INT PRIMARY KEY,
  nombre    VARCHAR(15) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS color (
  id_color SERIAL PRIMARY KEY,
  nombre   VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS tipo_multimedia (
  id_tipo_multimedia INT PRIMARY KEY,
  nombre             VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS tipo_contacto (
  id_tipo_contacto INT PRIMARY KEY,
  nombre           VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS provincia (
  id_provincia SERIAL PRIMARY KEY,
  nombre       VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS canton (
  id_canton    SERIAL PRIMARY KEY,
  id_provincia INT NOT NULL REFERENCES provincia(id_provincia),
  nombre       VARCHAR(60) NOT NULL,
  UNIQUE (id_provincia, nombre)
);

CREATE TABLE IF NOT EXISTS sector (
  id_sector SERIAL PRIMARY KEY,
  id_canton INT NOT NULL REFERENCES canton(id_canton),
  nombre    VARCHAR(80) NOT NULL,
  UNIQUE (id_canton, nombre)
);

CREATE TABLE IF NOT EXISTS tipo_notificacion (
  id_tipo_notificacion INT PRIMARY KEY,
  nombre               VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS tipo_accion (
  id_tipo_accion INT PRIMARY KEY,
  nombre         VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS estado_coincidencia (
  id_estado INT PRIMARY KEY,
  nombre    VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS criterio_ia (
  id_criterio INT PRIMARY KEY,
  nombre      VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS estado_solicitud (
  id_estado_solicitud INT PRIMARY KEY,
  nombre              VARCHAR(20) NOT NULL UNIQUE
);

-- ---------- Usuarios y cuentas ----------
CREATE TABLE IF NOT EXISTS ubicacion (
  id_ubicacion SERIAL PRIMARY KEY,
  id_sector    INT NOT NULL REFERENCES sector(id_sector),
  direccion    VARCHAR(200),
  latitud      DECIMAL(9,6),
  longitud     DECIMAL(9,6)
);

CREATE TABLE IF NOT EXISTS usuario (
  id_usuario         SERIAL PRIMARY KEY,
  id_rol             INT NOT NULL REFERENCES rol(id_rol),
  id_estado_cuenta   INT NOT NULL DEFAULT 1 REFERENCES estado_cuenta(id_estado_cuenta),
  nombres            VARCHAR(80) NOT NULL,
  apellidos          VARCHAR(80) NOT NULL,
  correo             VARCHAR(120) NOT NULL UNIQUE,
  contrasena_hash    VARCHAR(255) NOT NULL,
  telefono           VARCHAR(15),
  fecha_verificacion TIMESTAMP,
  fecha_registro     TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS token_usuario (
  id_token      SERIAL PRIMARY KEY,
  id_usuario    INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  id_tipo_token INT NOT NULL REFERENCES tipo_token(id_tipo_token),
  token_hash    VARCHAR(255) NOT NULL UNIQUE,
  expira_en     TIMESTAMP NOT NULL,
  fecha_uso     TIMESTAMP
);

CREATE TABLE IF NOT EXISTS consentimiento (
  id_consentimiento SERIAL PRIMARY KEY,
  id_usuario        INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  version_politica  VARCHAR(10) NOT NULL,
  fecha_aceptacion  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS preferencia_alerta (
  id_usuario   INT PRIMARY KEY REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  id_ubicacion INT NOT NULL REFERENCES ubicacion(id_ubicacion),
  radio_km     INT NOT NULL DEFAULT 5 CHECK (radio_km BETWEEN 1 AND 50)
);

CREATE TABLE IF NOT EXISTS refugio (
  id_refugio   SERIAL PRIMARY KEY,
  id_usuario   INT NOT NULL UNIQUE REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  id_ubicacion INT NOT NULL REFERENCES ubicacion(id_ubicacion),
  nombre       VARCHAR(100) NOT NULL,
  autorizado   BOOLEAN NOT NULL DEFAULT FALSE
);

-- ---------- Publicaciones ----------
CREATE TABLE IF NOT EXISTS publicacion (
  id_publicacion SERIAL PRIMARY KEY,
  id_usuario     INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  id_tipo        INT NOT NULL REFERENCES tipo_publicacion(id_tipo),
  id_estado      INT NOT NULL REFERENCES estado_publicacion(id_estado),
  id_especie     INT NOT NULL REFERENCES especie(id_especie),
  id_raza        INT REFERENCES raza(id_raza),
  id_tamano      INT REFERENCES tamano(id_tamano),
  nombre_animal  VARCHAR(60),
  descripcion    TEXT NOT NULL,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_publicacion_tipo ON publicacion(id_tipo, id_estado);

CREATE TABLE IF NOT EXISTS publicacion_color (
  id_publicacion INT REFERENCES publicacion(id_publicacion) ON DELETE CASCADE,
  id_color       INT REFERENCES color(id_color),
  PRIMARY KEY (id_publicacion, id_color)
);

-- Reporte: mascota desaparecida o animal encontrado
CREATE TABLE IF NOT EXISTS reporte (
  id_publicacion INT PRIMARY KEY REFERENCES publicacion(id_publicacion) ON DELETE CASCADE,
  id_ubicacion   INT NOT NULL REFERENCES ubicacion(id_ubicacion),
  fecha_evento   DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS adopcion (
  id_publicacion INT PRIMARY KEY REFERENCES publicacion(id_publicacion) ON DELETE CASCADE,
  estado_salud   VARCHAR(200) NOT NULL
);

CREATE TABLE IF NOT EXISTS contacto_publicacion (
  id_contacto      SERIAL PRIMARY KEY,
  id_publicacion   INT NOT NULL REFERENCES publicacion(id_publicacion) ON DELETE CASCADE,
  id_tipo_contacto INT NOT NULL REFERENCES tipo_contacto(id_tipo_contacto),
  valor            VARCHAR(120) NOT NULL
);

CREATE TABLE IF NOT EXISTS multimedia (
  id_multimedia      SERIAL PRIMARY KEY,
  id_publicacion     INT NOT NULL REFERENCES publicacion(id_publicacion) ON DELETE CASCADE,
  id_tipo_multimedia INT NOT NULL REFERENCES tipo_multimedia(id_tipo_multimedia),
  url                VARCHAR(255) NOT NULL,
  es_valida_ia       BOOLEAN
);

-- Contenido binario de cada archivo (así las fotos no se pierden al reiniciar el servidor)
CREATE TABLE IF NOT EXISTS multimedia_archivo (
  id_multimedia INT PRIMARY KEY REFERENCES multimedia(id_multimedia) ON DELETE CASCADE,
  mime          VARCHAR(40) NOT NULL,
  datos         BYTEA NOT NULL
);

-- ---------- Inteligencia artificial ----------
CREATE TABLE IF NOT EXISTS coincidencia (
  id_coincidencia SERIAL PRIMARY KEY,
  id_desaparecida INT NOT NULL REFERENCES reporte(id_publicacion) ON DELETE CASCADE,
  id_encontrada   INT NOT NULL REFERENCES reporte(id_publicacion) ON DELETE CASCADE,
  id_estado       INT NOT NULL DEFAULT 1 REFERENCES estado_coincidencia(id_estado),
  porcentaje      DECIMAL(5,2) NOT NULL,
  fecha_analisis  TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE (id_desaparecida, id_encontrada)
);

CREATE TABLE IF NOT EXISTS coincidencia_criterio (
  id_coincidencia INT REFERENCES coincidencia(id_coincidencia) ON DELETE CASCADE,
  id_criterio     INT REFERENCES criterio_ia(id_criterio),
  puntaje         DECIMAL(5,2) NOT NULL,
  PRIMARY KEY (id_coincidencia, id_criterio)
);

-- ---------- Administración y auditoría ----------
CREATE TABLE IF NOT EXISTS moderacion (
  id_moderacion  SERIAL PRIMARY KEY,
  id_admin       INT NOT NULL REFERENCES usuario(id_usuario),
  id_publicacion INT REFERENCES publicacion(id_publicacion) ON DELETE SET NULL,
  id_tipo_accion INT NOT NULL REFERENCES tipo_accion(id_tipo_accion),
  motivo         VARCHAR(255) NOT NULL,
  fecha_hora     TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS control_cuenta (
  id_control      SERIAL PRIMARY KEY,
  id_admin        INT NOT NULL REFERENCES usuario(id_usuario),
  id_usuario      INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  id_estado_nuevo INT NOT NULL REFERENCES estado_cuenta(id_estado_cuenta),
  motivo          VARCHAR(255) NOT NULL,
  fecha_hora      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notificacion (
  id_notificacion      SERIAL PRIMARY KEY,
  id_usuario           INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  id_publicacion       INT REFERENCES publicacion(id_publicacion) ON DELETE CASCADE,
  id_tipo_notificacion INT NOT NULL REFERENCES tipo_notificacion(id_tipo_notificacion),
  mensaje              VARCHAR(255) NOT NULL,
  leida                BOOLEAN NOT NULL DEFAULT FALSE,
  fecha                TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notificacion_usuario ON notificacion(id_usuario, leida);

-- ---------- Refugios: valoraciones y donaciones ----------
CREATE TABLE IF NOT EXISTS valoracion (
  id_valoracion SERIAL PRIMARY KEY,
  id_refugio    INT NOT NULL REFERENCES refugio(id_refugio) ON DELETE CASCADE,
  id_usuario    INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  calificacion  INT NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
  comentario    TEXT,
  fecha         TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE (id_refugio, id_usuario)
);

CREATE TABLE IF NOT EXISTS solicitud_donacion (
  id_solicitud        SERIAL PRIMARY KEY,
  id_refugio          INT NOT NULL REFERENCES refugio(id_refugio) ON DELETE CASCADE,
  id_estado_solicitud INT NOT NULL DEFAULT 1 REFERENCES estado_solicitud(id_estado_solicitud),
  titulo              VARCHAR(100) NOT NULL,
  descripcion         TEXT NOT NULL,
  fecha               TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Aporte registrado (dinero comprometido o insumos). Sin pagos en línea: exclusión del alcance.
CREATE TABLE IF NOT EXISTS donacion (
  id_donacion  SERIAL PRIMARY KEY,
  id_usuario   INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  id_refugio   INT NOT NULL REFERENCES refugio(id_refugio) ON DELETE CASCADE,
  id_solicitud INT REFERENCES solicitud_donacion(id_solicitud) ON DELETE SET NULL,
  monto        DECIMAL(10,2) CHECK (monto IS NULL OR monto > 0),
  detalle      VARCHAR(255),
  fecha        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------- Datos de catálogo ----------
INSERT INTO rol VALUES (1, 'Ciudadano'), (2, 'Refugio'), (3, 'Administrador') ON CONFLICT DO NOTHING;
INSERT INTO estado_cuenta VALUES (1, 'Activa'), (2, 'Suspendida'), (3, 'Bloqueada') ON CONFLICT DO NOTHING;
INSERT INTO tipo_token VALUES (1, 'Recuperación'), (2, 'Verificación') ON CONFLICT DO NOTHING;
INSERT INTO tipo_publicacion VALUES (1, 'Desaparecida'), (2, 'Encontrada'), (3, 'Adopción') ON CONFLICT DO NOTHING;
INSERT INTO estado_publicacion VALUES
  (1, 1, 'Pendiente'), (2, 1, 'Recuperada'),
  (3, 2, 'Pendiente'), (4, 2, 'Entregada'),
  (5, 3, 'Disponible'), (6, 3, 'Adoptado')
ON CONFLICT DO NOTHING;
INSERT INTO especie VALUES (1, 'Perro'), (2, 'Gato'), (3, 'Ave'), (4, 'Conejo'), (5, 'Otro') ON CONFLICT DO NOTHING;
INSERT INTO raza (id_especie, nombre) VALUES
  (1, 'Mestizo'), (1, 'Labrador'), (1, 'Golden Retriever'), (1, 'Pastor Alemán'), (1, 'Poodle'), (1, 'Chihuahua'),
  (1, 'Bulldog'), (1, 'Pitbull'), (1, 'Schnauzer'), (1, 'Husky'), (1, 'Beagle'), (1, 'Shih Tzu'), (1, 'Pug'),
  (2, 'Mestizo'), (2, 'Siamés'), (2, 'Persa'), (2, 'Angora'), (2, 'Bengalí'),
  (3, 'Perico'), (3, 'Loro'), (3, 'Canario'),
  (4, 'Mestizo'), (4, 'Cabeza de león'),
  (5, 'No aplica')
ON CONFLICT DO NOTHING;
INSERT INTO tamano VALUES (1, 'Pequeño'), (2, 'Mediano'), (3, 'Grande') ON CONFLICT DO NOTHING;
INSERT INTO color (nombre) VALUES
  ('Negro'), ('Blanco'), ('Café'), ('Gris'), ('Dorado'), ('Crema'), ('Beige'), ('Naranja'), ('Atigrado'), ('Manchado')
ON CONFLICT DO NOTHING;
INSERT INTO tipo_multimedia VALUES (1, 'Imagen'), (2, 'Video') ON CONFLICT DO NOTHING;
INSERT INTO tipo_contacto VALUES (1, 'Teléfono'), (2, 'WhatsApp'), (3, 'Correo') ON CONFLICT DO NOTHING;
INSERT INTO tipo_notificacion VALUES
  (1, 'Alerta de proximidad'), (2, 'Coincidencia IA'), (3, 'Interés en adopción'), (4, 'Moderación'), (5, 'Cuenta')
ON CONFLICT DO NOTHING;
INSERT INTO tipo_accion VALUES (1, 'Eliminar'), (2, 'Advertencia'), (3, 'Actualizar') ON CONFLICT DO NOTHING;
INSERT INTO estado_coincidencia VALUES (1, 'Sugerida'), (2, 'Confirmada'), (3, 'Descartada') ON CONFLICT DO NOTHING;
INSERT INTO criterio_ia VALUES
  (1, 'Especie'), (2, 'Raza'), (3, 'Color'), (4, 'Tamaño'), (5, 'Ubicación'), (6, 'Fecha'), (7, 'Imagen')
ON CONFLICT DO NOTHING;
INSERT INTO estado_solicitud VALUES (1, 'Abierta'), (2, 'Cerrada') ON CONFLICT DO NOTHING;

-- Provincias, cantones y sectores del Ecuador (las 24 provincias, cantones principales y varios sectores por cantón)
INSERT INTO provincia (nombre) VALUES
  ('Azuay'),
  ('Bolívar'),
  ('Cañar'),
  ('Carchi'),
  ('Chimborazo'),
  ('Cotopaxi'),
  ('El Oro'),
  ('Esmeraldas'),
  ('Galápagos'),
  ('Guayas'),
  ('Imbabura'),
  ('Loja'),
  ('Los Ríos'),
  ('Manabí'),
  ('Morona Santiago'),
  ('Napo'),
  ('Orellana'),
  ('Pastaza'),
  ('Pichincha'),
  ('Santa Elena'),
  ('Santo Domingo de los Tsáchilas'),
  ('Sucumbíos'),
  ('Tungurahua'),
  ('Zamora Chinchipe')
ON CONFLICT DO NOTHING;
INSERT INTO canton (id_provincia, nombre)
SELECT p.id_provincia, c.nombre FROM provincia p
JOIN (VALUES
  ('Azuay', 'Cuenca'),
  ('Azuay', 'Gualaceo'),
  ('Azuay', 'Paute'),
  ('Bolívar', 'Guaranda'),
  ('Bolívar', 'San Miguel'),
  ('Bolívar', 'Chillanes'),
  ('Cañar', 'Azogues'),
  ('Cañar', 'La Troncal'),
  ('Cañar', 'Cañar'),
  ('Carchi', 'Tulcán'),
  ('Carchi', 'Montúfar'),
  ('Carchi', 'Espejo'),
  ('Chimborazo', 'Riobamba'),
  ('Chimborazo', 'Guano'),
  ('Chimborazo', 'Alausí'),
  ('Cotopaxi', 'Latacunga'),
  ('Cotopaxi', 'Salcedo'),
  ('Cotopaxi', 'Pujilí'),
  ('El Oro', 'Machala'),
  ('El Oro', 'Pasaje'),
  ('El Oro', 'Santa Rosa'),
  ('El Oro', 'Huaquillas'),
  ('Esmeraldas', 'Esmeraldas'),
  ('Esmeraldas', 'Atacames'),
  ('Esmeraldas', 'Quinindé'),
  ('Galápagos', 'Santa Cruz'),
  ('Galápagos', 'San Cristóbal'),
  ('Galápagos', 'Isabela'),
  ('Guayas', 'Milagro'),
  ('Guayas', 'Guayaquil'),
  ('Guayas', 'Durán'),
  ('Guayas', 'Naranjito'),
  ('Guayas', 'Yaguachi'),
  ('Guayas', 'Simón Bolívar'),
  ('Guayas', 'Samborondón'),
  ('Guayas', 'Daule'),
  ('Guayas', 'Playas'),
  ('Guayas', 'El Triunfo'),
  ('Guayas', 'Marcelino Maridueña'),
  ('Imbabura', 'Ibarra'),
  ('Imbabura', 'Otavalo'),
  ('Imbabura', 'Cotacachi'),
  ('Imbabura', 'Antonio Ante'),
  ('Loja', 'Loja'),
  ('Loja', 'Catamayo'),
  ('Loja', 'Macará'),
  ('Los Ríos', 'Babahoyo'),
  ('Los Ríos', 'Quevedo'),
  ('Los Ríos', 'Vinces'),
  ('Los Ríos', 'Ventanas'),
  ('Los Ríos', 'Buena Fe'),
  ('Manabí', 'Portoviejo'),
  ('Manabí', 'Manta'),
  ('Manabí', 'Chone'),
  ('Manabí', 'Jipijapa'),
  ('Manabí', 'Sucre'),
  ('Manabí', 'El Carmen'),
  ('Morona Santiago', 'Morona'),
  ('Morona Santiago', 'Sucúa'),
  ('Morona Santiago', 'Gualaquiza'),
  ('Napo', 'Tena'),
  ('Napo', 'Archidona'),
  ('Napo', 'El Chaco'),
  ('Orellana', 'Francisco de Orellana'),
  ('Orellana', 'La Joya de los Sachas'),
  ('Orellana', 'Loreto'),
  ('Pastaza', 'Pastaza'),
  ('Pastaza', 'Mera'),
  ('Pastaza', 'Santa Clara'),
  ('Pichincha', 'Quito'),
  ('Pichincha', 'Rumiñahui'),
  ('Pichincha', 'Cayambe'),
  ('Pichincha', 'Mejía'),
  ('Pichincha', 'Pedro Moncayo'),
  ('Santa Elena', 'Santa Elena'),
  ('Santa Elena', 'La Libertad'),
  ('Santa Elena', 'Salinas'),
  ('Santo Domingo de los Tsáchilas', 'Santo Domingo'),
  ('Santo Domingo de los Tsáchilas', 'La Concordia'),
  ('Sucumbíos', 'Lago Agrio'),
  ('Sucumbíos', 'Shushufindi'),
  ('Sucumbíos', 'Cascales'),
  ('Tungurahua', 'Ambato'),
  ('Tungurahua', 'Baños de Agua Santa'),
  ('Tungurahua', 'Pelileo'),
  ('Tungurahua', 'Píllaro'),
  ('Zamora Chinchipe', 'Zamora'),
  ('Zamora Chinchipe', 'Yantzaza'),
  ('Zamora Chinchipe', 'Centinela del Cóndor')
) AS c(provincia, nombre) ON c.provincia = p.nombre
ON CONFLICT DO NOTHING;
INSERT INTO sector (id_canton, nombre)
SELECT c.id_canton, s.nombre FROM canton c
JOIN provincia p ON p.id_provincia = c.id_provincia
JOIN (VALUES
  ('Azuay', 'Cuenca', 'Centro Histórico'),
  ('Azuay', 'Cuenca', 'El Batán'),
  ('Azuay', 'Cuenca', 'Totoracocha'),
  ('Azuay', 'Cuenca', 'Monay'),
  ('Azuay', 'Cuenca', 'Ricaurte'),
  ('Azuay', 'Cuenca', 'Baños'),
  ('Azuay', 'Cuenca', 'El Vecino'),
  ('Azuay', 'Gualaceo', 'Centro'),
  ('Azuay', 'Gualaceo', 'Bullcay'),
  ('Azuay', 'Gualaceo', 'San Juan'),
  ('Azuay', 'Paute', 'Centro'),
  ('Azuay', 'Paute', 'Bulán'),
  ('Azuay', 'Paute', 'Chicán'),
  ('Bolívar', 'Guaranda', 'Centro'),
  ('Bolívar', 'Guaranda', 'Guanujo'),
  ('Bolívar', 'Guaranda', 'Veintimilla'),
  ('Bolívar', 'Guaranda', 'San Lorenzo'),
  ('Bolívar', 'San Miguel', 'Centro'),
  ('Bolívar', 'San Miguel', 'Santiago'),
  ('Bolívar', 'San Miguel', 'San Pablo'),
  ('Bolívar', 'Chillanes', 'Centro'),
  ('Bolívar', 'Chillanes', 'San José del Tambo'),
  ('Bolívar', 'Chillanes', 'Norte'),
  ('Cañar', 'Azogues', 'Centro'),
  ('Cañar', 'Azogues', 'Bayas'),
  ('Cañar', 'Azogues', 'Borrero'),
  ('Cañar', 'Azogues', 'Charasol'),
  ('Cañar', 'La Troncal', 'Centro'),
  ('Cañar', 'La Troncal', 'Manuel J. Calle'),
  ('Cañar', 'La Troncal', 'Pancho Negro'),
  ('Cañar', 'Cañar', 'Centro'),
  ('Cañar', 'Cañar', 'Chorocopte'),
  ('Cañar', 'Cañar', 'Honorato Vásquez'),
  ('Carchi', 'Tulcán', 'Centro'),
  ('Carchi', 'Tulcán', 'González Suárez'),
  ('Carchi', 'Tulcán', 'Julio Andrade'),
  ('Carchi', 'Tulcán', 'Tufiño'),
  ('Carchi', 'Montúfar', 'San Gabriel Centro'),
  ('Carchi', 'Montúfar', 'Cristóbal Colón'),
  ('Carchi', 'Montúfar', 'Fernández Salvador'),
  ('Carchi', 'Espejo', 'El Ángel Centro'),
  ('Carchi', 'Espejo', 'La Libertad'),
  ('Carchi', 'Espejo', 'San Isidro'),
  ('Chimborazo', 'Riobamba', 'Centro'),
  ('Chimborazo', 'Riobamba', 'Lizarzaburu'),
  ('Chimborazo', 'Riobamba', 'Maldonado'),
  ('Chimborazo', 'Riobamba', 'Velasco'),
  ('Chimborazo', 'Riobamba', 'Yaruquíes'),
  ('Chimborazo', 'Riobamba', 'Licán'),
  ('Chimborazo', 'Guano', 'Centro'),
  ('Chimborazo', 'Guano', 'San Andrés'),
  ('Chimborazo', 'Guano', 'Ilapo'),
  ('Chimborazo', 'Alausí', 'Centro'),
  ('Chimborazo', 'Alausí', 'Tixán'),
  ('Chimborazo', 'Alausí', 'Sibambe'),
  ('Cotopaxi', 'Latacunga', 'Centro'),
  ('Cotopaxi', 'Latacunga', 'La Matriz'),
  ('Cotopaxi', 'Latacunga', 'San Buenaventura'),
  ('Cotopaxi', 'Latacunga', 'Eloy Alfaro'),
  ('Cotopaxi', 'Latacunga', 'Ignacio Flores'),
  ('Cotopaxi', 'Salcedo', 'Centro'),
  ('Cotopaxi', 'Salcedo', 'Panzaleo'),
  ('Cotopaxi', 'Salcedo', 'Mulliquindil'),
  ('Cotopaxi', 'Pujilí', 'Centro'),
  ('Cotopaxi', 'Pujilí', 'La Victoria'),
  ('Cotopaxi', 'Pujilí', 'Zumbahua'),
  ('El Oro', 'Machala', 'Centro'),
  ('El Oro', 'Machala', 'Puerto Bolívar'),
  ('El Oro', 'Machala', 'La Providencia'),
  ('El Oro', 'Machala', 'El Cambio'),
  ('El Oro', 'Machala', 'Nueve de Mayo'),
  ('El Oro', 'Pasaje', 'Centro'),
  ('El Oro', 'Pasaje', 'Bolívar'),
  ('El Oro', 'Pasaje', 'Ochoa León'),
  ('El Oro', 'Santa Rosa', 'Centro'),
  ('El Oro', 'Santa Rosa', 'Jambelí'),
  ('El Oro', 'Santa Rosa', 'Puerto Jelí'),
  ('El Oro', 'Huaquillas', 'Centro'),
  ('El Oro', 'Huaquillas', 'Milton Reyes'),
  ('El Oro', 'Huaquillas', 'Hualtaco'),
  ('Esmeraldas', 'Esmeraldas', 'Centro'),
  ('Esmeraldas', 'Esmeraldas', 'Las Palmas'),
  ('Esmeraldas', 'Esmeraldas', 'Bartolomé Ruiz'),
  ('Esmeraldas', 'Esmeraldas', 'Luis Tello'),
  ('Esmeraldas', 'Esmeraldas', 'Tachina'),
  ('Esmeraldas', 'Atacames', 'Centro'),
  ('Esmeraldas', 'Atacames', 'Súa'),
  ('Esmeraldas', 'Atacames', 'Tonsupa'),
  ('Esmeraldas', 'Quinindé', 'Centro'),
  ('Esmeraldas', 'Quinindé', 'La Unión'),
  ('Esmeraldas', 'Quinindé', 'Malimpia'),
  ('Galápagos', 'Santa Cruz', 'Puerto Ayora'),
  ('Galápagos', 'Santa Cruz', 'Bellavista'),
  ('Galápagos', 'Santa Cruz', 'Santa Rosa'),
  ('Galápagos', 'San Cristóbal', 'Puerto Baquerizo Moreno'),
  ('Galápagos', 'San Cristóbal', 'El Progreso'),
  ('Galápagos', 'San Cristóbal', 'Isla Floreana'),
  ('Galápagos', 'Isabela', 'Puerto Villamil'),
  ('Galápagos', 'Isabela', 'Tomás de Berlanga'),
  ('Galápagos', 'Isabela', 'Zona Alta'),
  ('Guayas', 'Milagro', 'Centro'),
  ('Guayas', 'Milagro', 'Las Piñas'),
  ('Guayas', 'Milagro', 'Los Chirijos'),
  ('Guayas', 'Milagro', 'Bellavista'),
  ('Guayas', 'Milagro', 'Ciudadela Universitaria'),
  ('Guayas', 'Milagro', 'Enrique Valdez'),
  ('Guayas', 'Milagro', 'Los Pinos'),
  ('Guayas', 'Milagro', 'San Miguel'),
  ('Guayas', 'Milagro', 'Chobo'),
  ('Guayas', 'Milagro', 'Mariscal Sucre'),
  ('Guayas', 'Guayaquil', 'Centro'),
  ('Guayas', 'Guayaquil', 'Urdesa'),
  ('Guayas', 'Guayaquil', 'Alborada'),
  ('Guayas', 'Guayaquil', 'Sauces'),
  ('Guayas', 'Guayaquil', 'Guasmo'),
  ('Guayas', 'Guayaquil', 'Kennedy'),
  ('Guayas', 'Guayaquil', 'Samanes'),
  ('Guayas', 'Guayaquil', 'Mapasingue'),
  ('Guayas', 'Guayaquil', 'Bastión Popular'),
  ('Guayas', 'Guayaquil', 'Los Ceibos'),
  ('Guayas', 'Guayaquil', 'Febres Cordero'),
  ('Guayas', 'Guayaquil', 'La Florida'),
  ('Guayas', 'Durán', 'Centro'),
  ('Guayas', 'Durán', 'El Recreo'),
  ('Guayas', 'Durán', 'Primavera'),
  ('Guayas', 'Durán', 'Abel Gilbert'),
  ('Guayas', 'Durán', 'Divino Niño'),
  ('Guayas', 'Naranjito', 'Centro'),
  ('Guayas', 'Naranjito', 'Norte'),
  ('Guayas', 'Naranjito', 'Sur'),
  ('Guayas', 'Yaguachi', 'Centro'),
  ('Guayas', 'Yaguachi', 'Yaguachi Viejo'),
  ('Guayas', 'Yaguachi', 'Virgen de Fátima'),
  ('Guayas', 'Yaguachi', 'Pedro J. Montero'),
  ('Guayas', 'Simón Bolívar', 'Centro'),
  ('Guayas', 'Simón Bolívar', 'Lorenzo de Garaicoa'),
  ('Guayas', 'Simón Bolívar', 'Norte'),
  ('Guayas', 'Samborondón', 'Centro'),
  ('Guayas', 'Samborondón', 'La Puntilla'),
  ('Guayas', 'Samborondón', 'Tarifa'),
  ('Guayas', 'Daule', 'Centro'),
  ('Guayas', 'Daule', 'La Aurora'),
  ('Guayas', 'Daule', 'Los Lojas'),
  ('Guayas', 'Playas', 'Centro'),
  ('Guayas', 'Playas', 'Engabao'),
  ('Guayas', 'Playas', 'Data de Villamil'),
  ('Guayas', 'El Triunfo', 'Centro'),
  ('Guayas', 'El Triunfo', 'Norte'),
  ('Guayas', 'El Triunfo', 'Sur'),
  ('Guayas', 'Marcelino Maridueña', 'Centro'),
  ('Guayas', 'Marcelino Maridueña', 'Norte'),
  ('Guayas', 'Marcelino Maridueña', 'Sur'),
  ('Imbabura', 'Ibarra', 'Centro'),
  ('Imbabura', 'Ibarra', 'Caranqui'),
  ('Imbabura', 'Ibarra', 'Alpachaca'),
  ('Imbabura', 'Ibarra', 'Yacucalle'),
  ('Imbabura', 'Ibarra', 'La Dolorosa del Priorato'),
  ('Imbabura', 'Ibarra', 'San Antonio'),
  ('Imbabura', 'Otavalo', 'Centro'),
  ('Imbabura', 'Otavalo', 'San Luis'),
  ('Imbabura', 'Otavalo', 'Jordán'),
  ('Imbabura', 'Otavalo', 'Peguche'),
  ('Imbabura', 'Cotacachi', 'Centro'),
  ('Imbabura', 'Cotacachi', 'Quiroga'),
  ('Imbabura', 'Cotacachi', 'Imantag'),
  ('Imbabura', 'Antonio Ante', 'Atuntaqui Centro'),
  ('Imbabura', 'Antonio Ante', 'Andrade Marín'),
  ('Imbabura', 'Antonio Ante', 'Chaltura'),
  ('Loja', 'Loja', 'Centro'),
  ('Loja', 'Loja', 'El Valle'),
  ('Loja', 'Loja', 'San Sebastián'),
  ('Loja', 'Loja', 'Sucre'),
  ('Loja', 'Loja', 'Punzara'),
  ('Loja', 'Catamayo', 'Centro'),
  ('Loja', 'Catamayo', 'San José'),
  ('Loja', 'Catamayo', 'Guayquichuma'),
  ('Loja', 'Macará', 'Centro'),
  ('Loja', 'Macará', 'Sabiango'),
  ('Loja', 'Macará', 'Larama'),
  ('Los Ríos', 'Babahoyo', 'Centro'),
  ('Los Ríos', 'Babahoyo', 'Barreiro'),
  ('Los Ríos', 'Babahoyo', 'Clemente Baquerizo'),
  ('Los Ríos', 'Babahoyo', 'El Salto'),
  ('Los Ríos', 'Babahoyo', 'Camilo Ponce'),
  ('Los Ríos', 'Quevedo', 'Centro'),
  ('Los Ríos', 'Quevedo', 'San Camilo'),
  ('Los Ríos', 'Quevedo', 'Siete de Octubre'),
  ('Los Ríos', 'Quevedo', 'Venus del Río Quevedo'),
  ('Los Ríos', 'Vinces', 'Centro'),
  ('Los Ríos', 'Vinces', 'Antonio Sotomayor'),
  ('Los Ríos', 'Vinces', 'Norte'),
  ('Los Ríos', 'Ventanas', 'Centro'),
  ('Los Ríos', 'Ventanas', 'Zapotal'),
  ('Los Ríos', 'Ventanas', 'Chacarita'),
  ('Los Ríos', 'Buena Fe', 'Centro'),
  ('Los Ríos', 'Buena Fe', 'Patricia Pilar'),
  ('Los Ríos', 'Buena Fe', 'San Jacinto'),
  ('Manabí', 'Portoviejo', 'Centro'),
  ('Manabí', 'Portoviejo', 'Andrés de Vera'),
  ('Manabí', 'Portoviejo', 'Colón'),
  ('Manabí', 'Portoviejo', 'Picoazá'),
  ('Manabí', 'Portoviejo', 'Los Tamarindos'),
  ('Manabí', 'Manta', 'Centro'),
  ('Manabí', 'Manta', 'Tarqui'),
  ('Manabí', 'Manta', 'Los Esteros'),
  ('Manabí', 'Manta', 'Barbasquillo'),
  ('Manabí', 'Manta', 'San Mateo'),
  ('Manabí', 'Chone', 'Centro'),
  ('Manabí', 'Chone', 'Santa Rita'),
  ('Manabí', 'Chone', 'Ricaurte'),
  ('Manabí', 'Jipijapa', 'Centro'),
  ('Manabí', 'Jipijapa', 'Puerto Cayo'),
  ('Manabí', 'Jipijapa', 'Membrillal'),
  ('Manabí', 'Sucre', 'Bahía de Caráquez'),
  ('Manabí', 'Sucre', 'Leónidas Plaza'),
  ('Manabí', 'Sucre', 'Charapotó'),
  ('Manabí', 'El Carmen', 'Centro'),
  ('Manabí', 'El Carmen', 'Wilfrido Loor'),
  ('Manabí', 'El Carmen', 'San Pedro de Suma'),
  ('Morona Santiago', 'Morona', 'Macas Centro'),
  ('Morona Santiago', 'Morona', 'General Proaño'),
  ('Morona Santiago', 'Morona', 'Sevilla Don Bosco'),
  ('Morona Santiago', 'Sucúa', 'Centro'),
  ('Morona Santiago', 'Sucúa', 'Huambi'),
  ('Morona Santiago', 'Sucúa', 'Asunción'),
  ('Morona Santiago', 'Gualaquiza', 'Centro'),
  ('Morona Santiago', 'Gualaquiza', 'Bomboiza'),
  ('Morona Santiago', 'Gualaquiza', 'Mercedes Molina'),
  ('Napo', 'Tena', 'Centro'),
  ('Napo', 'Tena', 'Muyuna'),
  ('Napo', 'Tena', 'Puerto Misahuallí'),
  ('Napo', 'Tena', 'Pano'),
  ('Napo', 'Archidona', 'Centro'),
  ('Napo', 'Archidona', 'Cotundo'),
  ('Napo', 'Archidona', 'San Pablo de Ushpayacu'),
  ('Napo', 'El Chaco', 'Centro'),
  ('Napo', 'El Chaco', 'Santa Rosa'),
  ('Napo', 'El Chaco', 'Gonzalo Díaz de Pineda'),
  ('Orellana', 'Francisco de Orellana', 'Coca Centro'),
  ('Orellana', 'Francisco de Orellana', 'Dayuma'),
  ('Orellana', 'Francisco de Orellana', 'Taracoa'),
  ('Orellana', 'Francisco de Orellana', 'El Dorado'),
  ('Orellana', 'La Joya de los Sachas', 'Centro'),
  ('Orellana', 'La Joya de los Sachas', 'Enokanqui'),
  ('Orellana', 'La Joya de los Sachas', 'San Carlos'),
  ('Orellana', 'Loreto', 'Centro'),
  ('Orellana', 'Loreto', 'Ávila Huiruno'),
  ('Orellana', 'Loreto', 'San José de Payamino'),
  ('Pastaza', 'Pastaza', 'Puyo Centro'),
  ('Pastaza', 'Pastaza', 'Tarqui'),
  ('Pastaza', 'Pastaza', 'Diez de Agosto'),
  ('Pastaza', 'Pastaza', 'Fátima'),
  ('Pastaza', 'Mera', 'Centro'),
  ('Pastaza', 'Mera', 'Shell'),
  ('Pastaza', 'Mera', 'Madre Tierra'),
  ('Pastaza', 'Santa Clara', 'Centro'),
  ('Pastaza', 'Santa Clara', 'San José'),
  ('Pastaza', 'Santa Clara', 'Norte'),
  ('Pichincha', 'Quito', 'Centro Histórico'),
  ('Pichincha', 'Quito', 'La Carolina'),
  ('Pichincha', 'Quito', 'La Mariscal'),
  ('Pichincha', 'Quito', 'Cumbayá'),
  ('Pichincha', 'Quito', 'Tumbaco'),
  ('Pichincha', 'Quito', 'Carcelén'),
  ('Pichincha', 'Quito', 'Quitumbe'),
  ('Pichincha', 'Quito', 'Chillogallo'),
  ('Pichincha', 'Quito', 'El Condado'),
  ('Pichincha', 'Quito', 'Conocoto'),
  ('Pichincha', 'Quito', 'Calderón'),
  ('Pichincha', 'Rumiñahui', 'Sangolquí Centro'),
  ('Pichincha', 'Rumiñahui', 'San Rafael'),
  ('Pichincha', 'Rumiñahui', 'Capelo'),
  ('Pichincha', 'Rumiñahui', 'San Pedro de Taboada'),
  ('Pichincha', 'Cayambe', 'Centro'),
  ('Pichincha', 'Cayambe', 'Juan Montalvo'),
  ('Pichincha', 'Cayambe', 'Ayora'),
  ('Pichincha', 'Mejía', 'Machachi Centro'),
  ('Pichincha', 'Mejía', 'Alóag'),
  ('Pichincha', 'Mejía', 'Tambillo'),
  ('Pichincha', 'Pedro Moncayo', 'Tabacundo Centro'),
  ('Pichincha', 'Pedro Moncayo', 'Tupigachi'),
  ('Pichincha', 'Pedro Moncayo', 'La Esperanza'),
  ('Santa Elena', 'Santa Elena', 'Centro'),
  ('Santa Elena', 'Santa Elena', 'Ballenita'),
  ('Santa Elena', 'Santa Elena', 'Colonche'),
  ('Santa Elena', 'Santa Elena', 'Manglaralto'),
  ('Santa Elena', 'Santa Elena', 'Montañita'),
  ('Santa Elena', 'La Libertad', 'Centro'),
  ('Santa Elena', 'La Libertad', 'Velasco Ibarra'),
  ('Santa Elena', 'La Libertad', 'Norte'),
  ('Santa Elena', 'La Libertad', 'Sur'),
  ('Santa Elena', 'Salinas', 'Centro'),
  ('Santa Elena', 'Salinas', 'Chipipe'),
  ('Santa Elena', 'Salinas', 'San Lorenzo'),
  ('Santa Elena', 'Salinas', 'José Luis Tamayo'),
  ('Santa Elena', 'Salinas', 'Anconcito'),
  ('Santo Domingo de los Tsáchilas', 'Santo Domingo', 'Centro'),
  ('Santo Domingo de los Tsáchilas', 'Santo Domingo', 'Chigüilpe'),
  ('Santo Domingo de los Tsáchilas', 'Santo Domingo', 'Bombolí'),
  ('Santo Domingo de los Tsáchilas', 'Santo Domingo', 'Zaracay'),
  ('Santo Domingo de los Tsáchilas', 'Santo Domingo', 'Abraham Calazacón'),
  ('Santo Domingo de los Tsáchilas', 'La Concordia', 'Centro'),
  ('Santo Domingo de los Tsáchilas', 'La Concordia', 'Monterrey'),
  ('Santo Domingo de los Tsáchilas', 'La Concordia', 'Plan Piloto'),
  ('Sucumbíos', 'Lago Agrio', 'Nueva Loja Centro'),
  ('Sucumbíos', 'Lago Agrio', 'Santa Cecilia'),
  ('Sucumbíos', 'Lago Agrio', 'General Farfán'),
  ('Sucumbíos', 'Lago Agrio', 'Dureno'),
  ('Sucumbíos', 'Shushufindi', 'Centro'),
  ('Sucumbíos', 'Shushufindi', 'Siete de Julio'),
  ('Sucumbíos', 'Shushufindi', 'San Roque'),
  ('Sucumbíos', 'Cascales', 'El Dorado de Cascales'),
  ('Sucumbíos', 'Cascales', 'Sevilla'),
  ('Sucumbíos', 'Cascales', 'Santa Rosa de Sucumbíos'),
  ('Tungurahua', 'Ambato', 'Centro'),
  ('Tungurahua', 'Ambato', 'Ficoa'),
  ('Tungurahua', 'Ambato', 'Huachi Chico'),
  ('Tungurahua', 'Ambato', 'Izamba'),
  ('Tungurahua', 'Ambato', 'Atocha'),
  ('Tungurahua', 'Ambato', 'La Merced'),
  ('Tungurahua', 'Baños de Agua Santa', 'Centro'),
  ('Tungurahua', 'Baños de Agua Santa', 'Ulba'),
  ('Tungurahua', 'Baños de Agua Santa', 'Río Verde'),
  ('Tungurahua', 'Pelileo', 'Centro'),
  ('Tungurahua', 'Pelileo', 'Salasaca'),
  ('Tungurahua', 'Pelileo', 'Huambaló'),
  ('Tungurahua', 'Píllaro', 'Centro'),
  ('Tungurahua', 'Píllaro', 'San Andrés'),
  ('Tungurahua', 'Píllaro', 'Marcos Espinel'),
  ('Zamora Chinchipe', 'Zamora', 'Centro'),
  ('Zamora Chinchipe', 'Zamora', 'Cumbaratza'),
  ('Zamora Chinchipe', 'Zamora', 'Timbara'),
  ('Zamora Chinchipe', 'Yantzaza', 'Centro'),
  ('Zamora Chinchipe', 'Yantzaza', 'Los Encuentros'),
  ('Zamora Chinchipe', 'Yantzaza', 'Chicaña'),
  ('Zamora Chinchipe', 'Centinela del Cóndor', 'Zumbi Centro'),
  ('Zamora Chinchipe', 'Centinela del Cóndor', 'Triunfo Dorado'),
  ('Zamora Chinchipe', 'Centinela del Cóndor', 'Panguintza')
) AS s(provincia, canton, nombre) ON s.provincia = p.nombre AND s.canton = c.nombre
ON CONFLICT DO NOTHING;
