# Trazabilidad de requerimientos — FindMyPet

Relación entre cada requerimiento funcional del Plan de Proyecto (sección 1.3.1), el código que lo implementa
y las pruebas automáticas que lo verifican.

| RF | Requerimiento | Implementación (backend) | Pantalla (frontend) | Prueba |
| --- | --- | --- | --- | --- |
| RF-01 | Registro de usuarios | `auth.controller.js` → `registro` | `Auth.jsx` → Registro | `auth.test.js` |
| RF-02 | Inicio y cierre de sesión | `auth.controller.js` → `login`, `renovar` | `Auth.jsx` → Login, `Navbar.jsx` | `auth.test.js` |
| RF-03 | Gestión de perfil | `perfil.controller.js` | `Perfil.jsx` | `auth.test.js` |
| RF-04 | Registro de mascota desaparecida | `publicaciones.controller.js` → `crear` | `Reportar.jsx` | `publicaciones.test.js` |
| RF-05 | Gestión de reportes de desaparecidas | `publicaciones.controller.js` → `actualizar`, `eliminar`, `misPublicaciones` | `MisReportes.jsx` | `publicaciones.test.js` |
| RF-06 | Estado de mascota desaparecida | `publicaciones.controller.js` → `cambiarEstado` | `MisReportes.jsx`, `Detalle.jsx` | `publicaciones.test.js` |
| RF-07 | Registro de animal encontrado | `publicaciones.controller.js` → `crear` | `Reportar.jsx` | `publicaciones.test.js` |
| RF-08 | Consulta de animales encontrados | `publicaciones.controller.js` → `listar`, `obtener` | `Listado.jsx`, `Detalle.jsx` | `publicaciones.test.js` |
| RF-09 | Análisis de coincidencias con IA | `services/coincidencias.service.js`, `lib/ia.js` | — | `ia.test.js` |
| RF-10 | Sugerencias de coincidencias | `coincidencias.controller.js` → `misCoincidencias` | `Coincidencias.jsx` | `ia.test.js` |
| RF-11 | Revisión de resultados sugeridos | `coincidencias.controller.js` → `responder` | `Coincidencias.jsx` | `ia.test.js` |
| RF-12 | Registro de animal en adopción | `publicaciones.controller.js` → `crear` (solo refugios autorizados) | `Reportar.jsx` | `publicaciones.test.js` |
| RF-13 | Consulta de adopciones | `publicaciones.controller.js` → `listar` | `Listado.jsx` (Adopción) | `publicaciones.test.js` |
| RF-14 | Estado de adopción | `publicaciones.controller.js` → `cambiarEstado` | `MisReportes.jsx` | `publicaciones.test.js` |
| RF-15 | Contacto para adopción | `publicaciones.controller.js` → `interesAdopcion` | `Detalle.jsx` | `publicaciones.test.js` |
| RF-16 | Búsqueda y filtros | `publicaciones.controller.js` → `listar` | `Inicio.jsx`, `Listado.jsx` | `publicaciones.test.js` |
| RF-17 | Moderación de publicaciones | `admin.controller.js` | `Admin.jsx` | `admin.test.js` |
| RF-18 | Recuperación de contraseña | `auth.controller.js` → `olvideContrasena`, `restablecerContrasena` | `Auth.jsx` → Olvide, Restablecer | `auth.test.js` |
| RF-19 | Control de acceso por roles | `middlewares/auth.js` → `verificarRol` | `Comunes.jsx` → `RutaPrivada` | `admin.test.js` |
| RF-20 | Registro de ubicación | `lib/ubicacion.js`, `db/schema.sql` (provincia, cantón, sector) | `SelectorUbicacion.jsx`, `Mapa.jsx` | `publicaciones.test.js`, `donaciones.test.js` |
| RF-21 | Carga de múltiples multimedia | `lib/archivos.js` | `Reportar.jsx` | `publicaciones.test.js` |
| RF-22 | Validación de imágenes con IA | `lib/ia.js` → `validarImagen` | `Reportar.jsx` | `ia.test.js` |
| RF-23 | Generación de carteles de búsqueda | — | `services/cartel.js`, `Detalle.jsx` | Prueba manual |
| RF-24 | Valoraciones y reseñas de refugios | `refugios.controller.js` → `valorar` | `Refugios.jsx` | `admin.test.js` |
| RF-25 | Sistema de donaciones o insumos | `donaciones.controller.js` | `Refugios.jsx`, `MiRefugio.jsx` | `admin.test.js`, `donaciones.test.js` |
| RF-26 | Alertas por proximidad geográfica | `services/alertas.service.js` | `Perfil.jsx` | `ia.test.js` |
