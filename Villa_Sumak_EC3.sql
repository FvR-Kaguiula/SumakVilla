-- ============================================================================
-- Sumak Villa - Script (MySQL 8.0+ / MySQL Workbench)
-- Contiene: 24 tablas base + carga de datos + consultas + particionamiento + trigger
-- ============================================================================

DROP DATABASE IF EXISTS SumakVillaDB;
CREATE DATABASE IF NOT EXISTS SumakVillaDB;
USE SumakVillaDB;

-- ==========================================================
-- BLOQUE 1: TABLAS MAESTRAS INDEPENDIENTES (CONFIGURACIÓN)
-- ==========================================================

CREATE TABLE Distrito (
    Id_dist INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(30) NOT NULL
);

CREATE TABLE Tipo_pago (
    Id_tipo_pag INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE Estado_ped (
    Id_estado INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(30) NOT NULL UNIQUE,
    Descripcion VARCHAR(250)
);

CREATE TABLE Estado_dep (
    Id_est_desp INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(30) NOT NULL UNIQUE,
    Descripcion VARCHAR(250)
);

CREATE TABLE Estado_comprob (
    Id_est_comp INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(30) NOT NULL UNIQUE,
    Descripcion VARCHAR(250)
);

CREATE TABLE Est_ord_comp (
    Id_est_oc INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(30) NOT NULL UNIQUE,
    Descripcion VARCHAR(250)
);

CREATE TABLE Categoria (
    Id_cat INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL UNIQUE,
    Descripcion VARCHAR(250)
);

CREATE TABLE Almacen (
    Id_almacen INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(30) NOT NULL UNIQUE,
    Responsable VARCHAR(30) NOT NULL
);

CREATE TABLE Tecnica_perz (
    Id_tecnica INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL UNIQUE,
    Costo_ad DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    Descripcion VARCHAR(250),
    CONSTRAINT chk_costo_tecnica CHECK (Costo_ad >= 0.00) -- Mayor o igual a 0
);

-- ==========================================================
-- BLOQUE 2: ENTIDADES PRINCIPALES (CLIENTES Y PROVEEDORES)
-- ==========================================================

CREATE TABLE CLIENTE (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    razon_cli VARCHAR(50) NOT NULL,
    fecha_reg DATE NOT NULL,
    Direccion VARCHAR(100) NOT NULL
);

CREATE TABLE contacto_cli (
    Id_cont_cli INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    Nombre VARCHAR(30) NOT NULL,
    Apellido VARCHAR(30) NOT NULL,
    Telefono VARCHAR(9) NOT NULL,
    Correo VARCHAR(100) NOT NULL UNIQUE,
    FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente)
);

CREATE TABLE Proveedor (
    Id_prov INT AUTO_INCREMENT PRIMARY KEY,
    Razon VARCHAR(50) NOT NULL,
    Ruc VARCHAR(11) NOT NULL UNIQUE,
    Direccion VARCHAR(100) NOT NULL,
    Telefono VARCHAR(9) NOT NULL,
    Telef VARCHAR(9),
    Correo VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Contacto_prov (
    Id_cont_prov INT AUTO_INCREMENT PRIMARY KEY,
    Id_prov INT NOT NULL,
    Nombre VARCHAR(30) NOT NULL,
    Apellido VARCHAR(30) NOT NULL,
    Telefono VARCHAR(9) NOT NULL,
    Correo VARCHAR(100) NOT NULL UNIQUE,
    FOREIGN KEY (Id_prov) REFERENCES Proveedor(Id_prov)
);

-- ==========================================================
-- BLOQUE 3: CATÁLOGO DE PRODUCTOS E INVENTARIO
-- ==========================================================

CREATE TABLE Producto (
    Id_prod INT AUTO_INCREMENT PRIMARY KEY,
    Id_cat INT NOT NULL,
    Id_tecnica INT NOT NULL,
    Nombre VARCHAR(50) NOT NULL,
    Precio_uni DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    Estado VARCHAR(30) NOT NULL DEFAULT 'ACTIVO',
    FOREIGN KEY (Id_cat) REFERENCES Categoria(Id_cat),
    FOREIGN KEY (Id_tecnica) REFERENCES Tecnica_perz(Id_tecnica),
    CONSTRAINT chk_precio_producto CHECK (Precio_uni > 0.00), -- Mayor a 0
    CONSTRAINT chk_estado_producto CHECK (Estado IN ('ACTIVO', 'INACTIVO'))
);

CREATE TABLE Inventario (
    Id_invent INT AUTO_INCREMENT PRIMARY KEY,
    Id_prod INT NOT NULL,
    stock_actual INT NOT NULL DEFAULT 0,
    stock_min INT NOT NULL DEFAULT 0,
    Ubicacion VARCHAR(30) NOT NULL,
    FOREIGN KEY (Id_prod) REFERENCES Producto(Id_prod),
    CONSTRAINT chk_stock_actual CHECK (stock_actual >= 0),
    CONSTRAINT chk_stock_min CHECK (stock_min >= 0)
);

CREATE TABLE Stock_alm (
    Id_stock INT AUTO_INCREMENT PRIMARY KEY,
    Id_almacen INT NOT NULL,
    Id_prod INT NOT NULL,
    Cant_disp INT NOT NULL DEFAULT 0,
    FOREIGN KEY (Id_almacen) REFERENCES Almacen(Id_almacen),
    FOREIGN KEY (Id_prod) REFERENCES Producto(Id_prod),
    CONSTRAINT chk_cant_disponible CHECK (Cant_disp >= 0)
);

CREATE TABLE Mov_invent (
    Id_mov INT AUTO_INCREMENT PRIMARY KEY,
    Id_prod INT NOT NULL,
    Tipo_mov VARCHAR(30) NOT NULL,
    Cantidad INT NOT NULL,
    Fecha DATE NOT NULL,
    Observacion VARCHAR(250),
    FOREIGN KEY (Id_prod) REFERENCES Producto(Id_prod),
    CONSTRAINT chk_cantidad_mov CHECK (Cantidad > 0), -- Al menos 1 artículo
    CONSTRAINT chk_tipo_movimiento CHECK (Tipo_mov IN ('INGRESO', 'SALIDA', 'AJUSTE'))
);

-- ==========================================================
-- BLOQUE 4: PROCESO COMERCIAL (PEDIDOS, DESPACHOS Y FACTURACIÓN)
-- ==========================================================

CREATE TABLE Pedido (
    Id_ped INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    Id_estado INT NOT NULL,
    Fecha_ped DATE NOT NULL,
    Fecha_ent DATE,
    Estado VARCHAR(30) NOT NULL DEFAULT 'PENDIENTE',
    Obs VARCHAR(250),
    FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente),
    FOREIGN KEY (Id_estado) REFERENCES Estado_ped(Id_estado),
    CONSTRAINT chk_estado_pedido CHECK (Estado IN ('PENDIENTE', 'ADMITIDO', 'PROCESADO', 'ENTREGADO', 'CANCELADO'))
);

CREATE TABLE Det_pedido (
    Id_det INT AUTO_INCREMENT PRIMARY KEY,
    Id_ped INT NOT NULL,
    Id_prod INT NOT NULL,
    Cantidad INT NOT NULL,
    Subtotal DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (Id_ped) REFERENCES Pedido(Id_ped),
    FOREIGN KEY (Id_prod) REFERENCES Producto(Id_prod),
    CONSTRAINT chk_cantidad_pedido CHECK (Cantidad > 0),
    CONSTRAINT chk_subtotal_pedido CHECK (Subtotal >= 0.00)
);

CREATE TABLE Despacho (
    Id_desp INT AUTO_INCREMENT PRIMARY KEY,
    Id_ped INT NOT NULL,
    Id_dist INT NOT NULL,
    Id_est_desp INT NOT NULL,
    Fecha_desp DATE NOT NULL,
    Direc_entrega VARCHAR(100) NOT NULL,
    Resp_entrega VARCHAR(30) NOT NULL,
    Estado_despacho VARCHAR(30) NOT NULL DEFAULT 'EN ALMACEN',
    FOREIGN KEY (Id_ped) REFERENCES Pedido(Id_ped),
    FOREIGN KEY (Id_dist) REFERENCES Distrito(Id_dist),
    FOREIGN KEY (Id_est_desp) REFERENCES Estado_dep(Id_est_desp),
    CONSTRAINT chk_estado_despacho CHECK (Estado_despacho IN ('EN ALMACEN', 'EN RUTA', 'ENTREGADO', 'RECHAZADO'))
);

CREATE TABLE Comprobante (
    Id_comprob INT AUTO_INCREMENT PRIMARY KEY,
    Id_ped INT NOT NULL,
    Id_est_comp INT NOT NULL,
    Tipo_comprob VARCHAR(30) NOT NULL DEFAULT 'BOLETA',
    Igv DECIMAL(10,2) NOT NULL DEFAULT 0.18,
    Fecha_emi DATE NOT NULL,
    Monto_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    Estado_comprob VARCHAR(30) NOT NULL DEFAULT 'EMITIDO',
    FOREIGN KEY (Id_ped) REFERENCES Pedido(Id_ped),
    FOREIGN KEY (Id_est_comp) REFERENCES Estado_comprob(Id_est_comp),
    CONSTRAINT chk_monto_comprob CHECK (Monto_total >= 0.00),
    CONSTRAINT chk_tipo_comprob CHECK (Tipo_comprob IN ('BOLETA', 'FACTURA')),
    CONSTRAINT chk_estado_comprob CHECK (Estado_comprob IN ('EMITIDO', 'PAGADO', 'ANULADO'))
);

CREATE TABLE Pago (
    Id_pago INT AUTO_INCREMENT PRIMARY KEY,
    Id_comprob INT NOT NULL,
    Id_tipo_pag INT NOT NULL,
    Fecha_pago DATE NOT NULL,
    Monto DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (Id_comprob) REFERENCES Comprobante(Id_comprob),
    FOREIGN KEY (Id_tipo_pag) REFERENCES Tipo_pago(Id_tipo_pag),
    CONSTRAINT chk_monto_pago CHECK (Monto > 0.00)
);

-- ==========================================================
-- BLOQUE 5: PROCESO LOGÍSTICO (ÓRDENES DE COMPRA AL PROVEEDOR)
-- ==========================================================

CREATE TABLE Orden_comp (
    Id_orden INT AUTO_INCREMENT PRIMARY KEY,
    Id_prov INT NOT NULL,
    Fecha_emi DATE NOT NULL,
    Fecha_ent DATE,
    Total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    Estado_orden VARCHAR(30) NOT NULL DEFAULT 'SOLICITADO',
    FOREIGN KEY (Id_prov) REFERENCES Proveedor(Id_prov),
    CONSTRAINT chk_total_orden CHECK (Total >= 0.00),
    CONSTRAINT chk_estado_orden CHECK (Estado_orden IN ('SOLICITADO', 'APROBADO', 'RECIBIDO', 'CANCELADO'))
);

CREATE TABLE Det_orden_comp (
    Id_det_oc INT AUTO_INCREMENT PRIMARY KEY,
    Id_orden INT NOT NULL,
    Id_prod INT NOT NULL,
    Id_est_oc INT NOT NULL,
    Cantidad INT NOT NULL,
    Subtotal DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (Id_orden) REFERENCES Orden_comp(Id_orden),
    FOREIGN KEY (Id_prod) REFERENCES Producto(Id_prod),
    FOREIGN KEY (Id_est_oc) REFERENCES Est_ord_comp(Id_est_oc),
    CONSTRAINT chk_cantidad_oc CHECK (Cantidad > 0),
    CONSTRAINT chk_subtotal_oc CHECK (Subtotal >= 0.00)
);

-- ============================================================================
-- CARGA DE DATOS (INSERTS)
-- ============================================================================

INSERT INTO Distrito VALUES
(1,'Villa El Salvador'),
(2,'Villa María del Triunfo'),
(3,'San Juan de Miraflores'),
(4,'Chorrillos'),
(5,'Lurín'),
(6,'Pachacámac'),
(7,'Surco'),
(8,'Barranco'),
(9,'Miraflores'),
(10,'San Isidro'),
(11,'La Molina'),
(12,'Ate'),
(13,'Santa Anita'),
(14,'El Agustino'),
(15,'La Victoria'),
(16,'Cercado de Lima'),
(17,'Breña'),
(18,'Jesús María'),
(19,'Pueblo Libre'),
(20,'Magdalena'),
(21,'San Miguel'),
(22,'Callao'),
(23,'Bellavista'),
(24,'La Perla'),
(25,'Ventanilla'),
(26,'Los Olivos'),
(27,'Comas'),
(28,'Independencia'),
(29,'Carabayllo'),
(30,'Puente Piedra'),
(31,'San Martín de Porres'),
(32,'Rímac'),
(33,'San Juan de Lurigancho'),
(34,'Lince'),
(35,'Surquillo'),
(36,'San Borja'),
(37,'Ancón'),
(38,'Santa Rosa'),
(39,'Chaclacayo'),
(40,'Cieneguilla'),
(41,'Pucusana'),
(42,'Punta Hermosa'),
(43,'Punta Negra'),
(44,'Santa María del Mar'),
(45,'Huachipa'),
(46,'Ñaña'),
(47,'Huaycán'),
(48,'Manchay'),
(49,'Chosica'),
(50,'Mala');


INSERT INTO Tipo_pago VALUES
(1,'Efectivo'),
(2,'Yape'),
(3,'Plin'),
(4,'Transferencia'),
(5,'Tarjeta');


INSERT INTO Estado_ped VALUES
(1,'Pendiente','Pedido registrado'),
(2,'Admitido','Pedido aceptado'),
(3,'Procesado','En producción'),
(4,'Entregado','Pedido culminado'),
(5,'Cancelado','Pedido anulado');


INSERT INTO Estado_dep VALUES
(1,'En Almacen','Preparando salida'),
(2,'En Ruta','Despachado'),
(3,'Entregado','Cliente recibió'),
(4,'Rechazado','Entrega rechazada'),
(5,'Reprogramado','Nueva fecha');


INSERT INTO Estado_comprob VALUES
(1,'Emitido','Comprobante generado'),
(2,'Pagado','Pago completo'),
(3,'Pendiente','Pago pendiente'),
(4,'Anulado','Comprobante anulado'),
(5,'Observado','Requiere revisión');


INSERT INTO Est_ord_comp VALUES
(1,'Solicitado','Orden generada'),
(2,'Aprobado','Orden aprobada'),
(3,'Recibido','Mercadería recibida'),
(4,'Parcial','Recepción parcial'),
(5,'Cancelado','Orden anulada');


INSERT INTO Almacen VALUES
(1,'Almacen Central','Carlos Ramos'),
(2,'Almacen Norte','José Mendoza'),
(3,'Almacen Sur','Luis Paredes'),
(4,'Almacen Produccion','María Torres'),
(5,'Almacen Despacho','Ana Quispe');


INSERT INTO Categoria VALUES
(1,'Polos Personalizados','Polos promocionales'),
(2,'Gorras','Gorras bordadas'),
(3,'Tazas','Tazas sublimadas'),
(4,'Tomatodos','Botellas promocionales'),
(5,'Llaveros','Llaveros corporativos'),
(6,'Mochilas','Mochilas publicitarias'),
(7,'Lapiceros','Lapiceros corporativos'),
(8,'Agendas','Agendas empresariales'),
(9,'USB Personalizados','Memorias USB'),
(10,'Bolsas Ecologicas','Bolsas reutilizables');


INSERT INTO Tecnica_perz VALUES
(1,'Sublimacion',5.00,'Impresion por calor'),
(2,'Serigrafia',4.50,'Impresion en tinta'),
(3,'Bordado',8.00,'Bordado computarizado'),
(4,'DTF',6.50,'Direct Transfer Film'),
(5,'Vinil Textil',4.00,'Aplicacion de vinil'),
(6,'Laser',7.50,'Grabado laser'),
(7,'UV',6.00,'Impresion UV'),
(8,'Tampografia',3.50,'Objetos pequeños'),
(9,'Transfer',5.50,'Transferencia termica'),
(10,'Relieve',9.00,'Acabado premium');


INSERT INTO CLIENTE VALUES
(1,'Colegio Trilce VES','2024-01-15','Sector 2 Grupo 10 Villa El Salvador'),
(2,'Academia Pamer Sur','2024-02-11','Av. El Sol 845 SJM'),
(3,'Municipalidad VES','2024-03-01','Av. Revolucion VES'),
(4,'Instituto SISE','2024-03-21','Av. Pachacutec VES'),
(5,'Colegio Peruano Japones','2024-04-12','La Molina'),
(6,'Corporacion Vega','2024-05-03','Lurin'),
(7,'Boticas Peru','2024-05-15','Surco'),
(8,'Colegio Prolog','2024-06-01','VMT'),
(9,'Universidad Autonoma','2024-06-11','Panamericana Sur'),
(10,'Universidad UTP','2024-06-20','Lima Centro'),
(11,'Caja Huancayo','2024-07-10','San Isidro'),
(12,'Caja Piura','2024-07-20','Miraflores'),
(13,'Notaria Fernandez','2024-08-01','VES'),
(14,'Innova Schools Chorrillos','2024-08-08','Chorrillos'),
(15,'Grupo AJE','2024-08-20','Ate'),
(16,'Grupo Gloria','2024-09-01','La Victoria'),
(17,'Tottus Atocongo','2024-09-10','SJM'),
(18,'Metro Chorrillos','2024-09-22','Chorrillos'),
(19,'Promart Atocongo','2024-10-01','SJM'),
(20,'Makro Villa El Salvador','2024-10-12','VES'),
(21,'Colegio Saco Oliveros','2024-11-05','SJM'),
(22,'Colegio Bertolt Brecht','2024-11-10','VES'),
(23,'Universidad Cientifica','2024-11-18','Villa'),
(24,'Instituto Certus','2024-12-02','Lima'),
(25,'Instituto IDAT','2024-12-15','Lima'),
(26,'Restaurante El Buen Sabor','2025-01-05','VES'),
(27,'Polleria El Rancho','2025-01-10','VES'),
(28,'Ferreteria San Juan','2025-01-15','SJM'),
(29,'Clinica San Pablo Sur','2025-01-20','Surco'),
(30,'Odonto Smile','2025-01-25','VES'),
(31,'Colegio Cristo Salvador','2025-02-01','VES'),
(32,'Colegio Maria Reiche','2025-02-05','SJM'),
(33,'Colegio Pitagoras','2025-02-10','VMT'),
(34,'Universidad Ricardo Palma','2025-02-15','Surco'),
(35,'Universidad Alas Peruanas','2025-02-20','Lima'),
(36,'Grupo Romero','2025-03-01','San Isidro'),
(37,'Mibanco','2025-03-05','Lima'),
(38,'Banco Pichincha','2025-03-10','San Isidro'),
(39,'Caja Arequipa','2025-03-15','Miraflores'),
(40,'Caja Sullana','2025-03-20','Lima'),
(41,'Veterinaria Huellitas','2025-04-01','VES'),
(42,'Farmacia Universal','2025-04-05','VES'),
(43,'Cevicheria Puerto Azul','2025-04-10','Chorrillos'),
(44,'Hotel Costa Sur','2025-04-15','Barranco'),
(45,'Gimnasio StrongFit','2025-04-20','VES'),
(46,'Colegio San Martin','2025-05-01','VES'),
(47,'Colegio Newton','2025-05-05','SJM'),
(48,'Instituto Peruano','2025-05-10','Lima'),
(49,'Transportes Sol del Sur','2025-05-15','Lurin'),
(50,'Constructora Andina','2025-05-20','Ate'),
(51,'Textiles Santa Rosa','2025-06-01','La Victoria'),
(52,'Imprenta Grafica Peru','2025-06-05','Lima'),
(53,'Market Sur Express','2025-06-10','VES'),
(54,'Agroindustrial Sol','2025-06-15','Lurin'),
(55,'Comercial VES SAC','2025-06-20','VES'),
(56,'Servicios Generales Diaz','2025-07-01','SJM'),
(57,'Asociacion Comerciantes VES','2025-07-05','VES'),
(58,'Corporacion San Pedro','2025-07-10','Lima'),
(59,'Fundacion Esperanza','2025-07-15','VES'),
(60,'ONG Creciendo Juntos','2025-07-20','Lima'),
(61,'Colegio San Ignacio','2026-01-05','Surco'),
(62,'Colegio Santa Maria','2026-01-10','VES'),
(63,'Academia Talentos','2026-01-15','VES'),
(64,'Instituto Tecnologico Lima','2026-01-20','Lima'),
(65,'Consultora Innova','2026-02-01','San Isidro'),
(66,'Empresa Minera Sur','2026-02-05','Lima'),
(67,'Electro Peru Servicios','2026-02-10','Lima'),
(68,'Cooperativa San Juan','2026-02-15','SJM'),
(69,'Panaderia Delicias','2026-03-01','VES'),
(70,'Corporacion Educativa Peru','2026-03-05','Lima'),
(71,'Eventos Premium SAC','2026-03-10','Miraflores'),
(72,'Producciones Creativas','2026-03-15','Barranco'),
(73,'Academia Lideres','2026-04-01','VES'),
(74,'Centro Medico Familiar','2026-04-05','VES'),
(75,'Distribuidora Los Andes','2026-04-10','Ate'),
(76,'Colegio Los Alamos','2026-04-15','VES'),
(77,'Grupo Constructor Lima','2026-05-01','Lurin'),
(78,'Inversiones del Sur SAC','2026-05-05','VES'),
(79,'Asociacion Deportiva VES','2026-05-10','VES'),
(80,'Centro Empresarial Pachacutec','2026-05-15','VES');


INSERT INTO contacto_cli VALUES
(1,1,'Carlos','Ramos','987654321','cramos1@gmail.com'),
(2,2,'Luis','Quispe','987654322','lquispe2@gmail.com'),
(3,3,'María','Torres','987654323','mtorres3@gmail.com'),
(4,4,'José','Flores','987654324','jflores4@gmail.com'),
(5,5,'Ana','Vargas','987654325','avargas5@gmail.com'),
(6,6,'Jorge','Paredes','987654326','jparedes6@gmail.com'),
(7,7,'Rosa','Huaman','987654327','rhuaman7@gmail.com'),
(8,8,'Pedro','Soto','987654328','psoto8@gmail.com'),
(9,9,'Lucia','Diaz','987654329','ldiaz9@gmail.com'),
(10,10,'Miguel','Castro','987654330','mcastro10@gmail.com'),
(11,11,'Carmen','Salas','987654331','csalas11@gmail.com'),
(12,12,'Ricardo','Leon','987654332','rleon12@gmail.com'),
(13,13,'Sandra','Mendoza','987654333','smendoza13@gmail.com'),
(14,14,'Juan','Garcia','987654334','jgarcia14@gmail.com'),
(15,15,'Patricia','Rojas','987654335','projas15@gmail.com'),
(16,16,'Fernando','Silva','987654336','fsilva16@gmail.com'),
(17,17,'Diana','Morales','987654337','dmorales17@gmail.com'),
(18,18,'Raul','Navarro','987654338','rnavarro18@gmail.com'),
(19,19,'Elena','Cruz','987654339','ecruz19@gmail.com'),
(20,20,'Victor','Lopez','987654340','vlopez20@gmail.com'),
(21,21,'Karla','Campos','987654341','kcampos21@gmail.com'),
(22,22,'Marco','Aguilar','987654342','maguilar22@gmail.com'),
(23,23,'Silvia','Peña','987654343','spena23@gmail.com'),
(24,24,'Daniel','Rivera','987654344','drivera24@gmail.com'),
(25,25,'Monica','Espinoza','987654345','mespinoza25@gmail.com'),
(26,26,'Edgar','Valdez','987654346','evaldez26@gmail.com'),
(27,27,'Paola','Benites','987654347','pbenites27@gmail.com'),
(28,28,'Hugo','Alva','987654348','halva28@gmail.com'),
(29,29,'Claudia','Ruiz','987654349','cruiz29@gmail.com'),
(30,30,'Roberto','Palacios','987654350','rpalacios30@gmail.com'),
(31,31,'Tatiana','Ortiz','987654351','tortiz31@gmail.com'),
(32,32,'Kevin','Chavez','987654352','kchavez32@gmail.com'),
(33,33,'Fiorella','Luna','987654353','fluna33@gmail.com'),
(34,34,'Bruno','Vega','987654354','bvega34@gmail.com'),
(35,35,'Milagros','Reyes','987654355','mreyes35@gmail.com'),
(36,36,'Diego','Arce','987654356','darce36@gmail.com'),
(37,37,'Vanessa','Mejia','987654357','vmejia37@gmail.com'),
(38,38,'Renzo','Fuentes','987654358','rfuentes38@gmail.com'),
(39,39,'Andrea','Cerna','987654359','acerna39@gmail.com'),
(40,40,'Oscar','Villacorta','987654360','ovillacorta40@gmail.com');
INSERT INTO contacto_cli VALUES
(41,41,'Luis','Gonzales','987654361','lgonzales41@gmail.com'),
(42,42,'Mariela','Castillo','987654362','mcastillo42@gmail.com'),
(43,43,'Javier','Ramirez','987654363','jramirez43@gmail.com'),
(44,44,'Patricia','Fernandez','987654364','pfernandez44@gmail.com'),
(45,45,'Alberto','Sanchez','987654365','asanchez45@gmail.com'),
(46,46,'Veronica','Gutierrez','987654366','vgutierrez46@gmail.com'),
(47,47,'Manuel','Delgado','987654367','mdelgado47@gmail.com'),
(48,48,'Roxana','Cordero','987654368','rcordero48@gmail.com'),
(49,49,'Cesar','Salazar','987654369','csalazar49@gmail.com'),
(50,50,'Liliana','Vasquez','987654370','lvasquez50@gmail.com'),
(51,51,'Eduardo','Carrasco','987654371','ecarrasco51@gmail.com'),
(52,52,'Natalia','Mora','987654372','nmora52@gmail.com'),
(53,53,'Felipe','Renteria','987654373','frenteria53@gmail.com'),
(54,54,'Yolanda','Chavez','987654374','ychavez54@gmail.com'),
(55,55,'Martin','Campos','987654375','mcampos55@gmail.com'),
(56,56,'Pamela','Valencia','987654376','pvalencia56@gmail.com'),
(57,57,'Sergio','Mendoza','987654377','smendoza57@gmail.com'),
(58,58,'Karen','Espinoza','987654378','kespinoza58@gmail.com'),
(59,59,'Victor','Rojas','987654379','vrojas59@gmail.com'),
(60,60,'Melissa','Navarro','987654380','mnavarro60@gmail.com'),
(61,61,'Fernando','Loayza','987654381','floayza61@gmail.com'),
(62,62,'Angela','Paredes','987654382','aparedes62@gmail.com'),
(63,63,'Christian','Huerta','987654383','chuerta63@gmail.com'),
(64,64,'Sandra','Cisneros','987654384','scisneros64@gmail.com'),
(65,65,'Diego','Villanueva','987654385','dvillanueva65@gmail.com'),
(66,66,'Brenda','Linares','987654386','blinares66@gmail.com'),
(67,67,'Oscar','Benavides','987654387','obenavides67@gmail.com'),
(68,68,'Milagros','Torres','987654388','mtorres68@gmail.com'),
(69,69,'Jose','Reategui','987654389','jreategui69@gmail.com'),
(70,70,'Gabriela','Velasquez','987654390','gvelasquez70@gmail.com'),
(71,71,'Ricardo','Cabrera','987654391','rcabrera71@gmail.com'),
(72,72,'Andrea','Herrera','987654392','aherrera72@gmail.com'),
(73,73,'Kevin','Moran','987654393','kmoran73@gmail.com'),
(74,74,'Lucero','Pezo','987654394','lpezo74@gmail.com'),
(75,75,'Jhonatan','Vilchez','987654395','jvilchez75@gmail.com'),
(76,76,'Carolina','Aguirre','987654396','caguirre76@gmail.com'),
(77,77,'Renato','Meza','987654397','rmeza77@gmail.com'),
(78,78,'Diana','Palomino','987654398','dpalomino78@gmail.com'),
(79,79,'Alex','Ortega','987654399','aortega79@gmail.com'),
(80,80,'Fiorella','Acosta','987654400','facosta80@gmail.com');


INSERT INTO Proveedor (Id_prov, Razon, Ruc, Direccion, Telefono, Correo) VALUES
(1,'Textiles Andinos SAC','20100000001','La Victoria, Lima','987700001','ventas@textilesandinos.pe'),
(2,'Peru Cotton Group SAC','20100000002','La Victoria, Lima','987700002','contacto@perucotton.pe'),
(3,'Importadora Textil Sur SAC','20100000003','Ate, Lima','987700003','ventas@textilsur.pe'),
(4,'Confecciones Santa Rosa SAC','20100000004','Gamarra, Lima','987700004','pedidos@santarosa.pe'),
(5,'Distribuidora de Telas Perú SAC','20100000005','La Victoria, Lima','987700005','ventas@telasperu.pe'),
(6,'Sublimaciones del Perú SAC','20100000006','Breña, Lima','987700006','ventas@sublimaciones.pe'),
(7,'Ink Transfer SAC','20100000007','Lince, Lima','987700007','contacto@inktransfer.pe'),
(8,'Master Sublimación SAC','20100000008','Surquillo, Lima','987700008','ventas@mastersublimacion.pe'),
(9,'Color Print Perú SAC','20100000009','Lima','987700009','ventas@colorprint.pe'),
(10,'DTF Solutions Perú SAC','20100000010','Ate, Lima','987700010','ventas@dtfsolutions.pe'),
(11,'Vinil Express SAC','20100000011','Surco, Lima','987700011','ventas@vinilexpress.pe'),
(12,'Transfer Pro SAC','20100000012','La Victoria, Lima','987700012','pedidos@transferpro.pe'),
(13,'Bordados Industriales SAC','20100000013','Ate, Lima','987700013','ventas@bordados.pe'),
(14,'Laser Perú SAC','20100000014','Av. San Borja, Lima','987700014','contacto@laserperu.pe'),
(15,'Impresiones UV SAC','20100000015','Av. Lima, Lima','987700015','ventas@uvperu.pe'),
(16,'Promocionales Perú SAC','20100000016','Av. Lince, Lima','987700016','ventas@promocionales.pe'),
(17,'Merchandising Express SAC','20100000017','Av. Miraflores, Lima','987700017','pedidos@merchandisingexpress.pe'),
(18,'Corporación Publicitaria SAC','20100000018','Av. San Isidro, Lima','987700018','ventas@corppublicitaria.pe'),
(19,'Regalos Empresariales Perú','20100000019','Av. Surco, Lima','987700019','ventas@regalosempresariales.pe'),
(20,'Artículos Promocionales SAC','20100000020','Av. Lima, Lima','987700020','contacto@promocionalesac.pe'),
(21,'Empaques Eco Perú SAC','20100000021','Av. Lurín, Lima','987700021','ventas@ecoempaques.pe'),
(22,'Bolsas Ecológicas SAC','20100000022','Av. Villa El Salvador, Lima','987700022','ventas@bolsaseco.pe'),
(23,'Packaging Perú SAC','20100000023','Av. Lurín, Lima','987700023','pedidos@packagingperu.pe'),
(24,'Cartones del Sur SAC','20100000024','Av. Villa El Salvador, Lima','987700024','ventas@cartonessur.pe'),
(25,'Cajas y Empaques SAC','20100000025','Av. Ate, Lima','987700025','ventas@cajasempaques.pe'),
(26,'Papelería Corporativa SAC','20100000026','Cercado de Lima','987700026','ventas@papeleriacorp.pe'),
(27,'Agendas Perú SAC','20100000027','Lima','987700027','ventas@agendasperu.pe'),
(28,'Imprenta Moderna SAC','20100000028','Breña, Lima','987700028','pedidos@imprentamoderna.pe'),
(29,'Gráfica Nacional SAC','20100000029','Lima','987700029','ventas@graficanacional.pe'),
(30,'Offset Perú SAC','20100000030','La Victoria, Lima','987700030','ventas@offsetperu.pe'),
(31,'USB Tech Perú SAC','20100000031','San Isidro, Lima','987700031','ventas@usbtech.pe'),
(32,'Power Bank Perú SAC','20100000032','Miraflores, Lima','987700032','ventas@powerbankperu.pe'),
(33,'Tecnología Promocional SAC','20100000033','Lima','987700033','contacto@tecpromo.pe'),
(34,'Importaciones Asia Perú SAC','20100000034','Callao','987700034','ventas@asiaperu.pe'),
(35,'Distribuidora Digital SAC','20100000035','Callao','987700035','ventas@digitaldistribuidora.pe'),
(36,'Plásticos Industriales SAC','20100000036','Lurín, Lima','987700036','ventas@plasticosind.pe'),
(37,'Tomatodos Perú SAC','20100000037','Villa El Salvador','987700037','ventas@tomatodosperu.pe'),
(38,'Tazas Premium SAC','20100000038','Breña, Lima','987700038','ventas@tazaspremium.pe'),
(39,'Llaveros Creativos SAC','20100000039','Lima','987700039','ventas@llaveroscreativos.pe'),
(40,'Mochilas Corporativas SAC','20100000040','Ate, Lima','987700040','ventas@mochilascorp.pe');
INSERT INTO Proveedor (Id_prov, Razon, Ruc, Direccion, Telefono, Correo) VALUES
(41,'Gorras del Perú SAC','20100000041','La Victoria, Lima','987700041','ventas@gorrasperu.pe'),
(42,'Polos Corporativos SAC','20100000042','Ate, Lima','987700042','ventas@poloscorporativos.pe'),
(43,'Uniformes Empresariales SAC','20100000043','San Juan de Lurigancho, Lima','987700043','ventas@uniformesemp.pe'),
(44,'Confecciones El Sol SAC','20100000044','La Victoria, Lima','987700044','ventas@confeccioneselsol.pe'),
(45,'Diseños Creativos Perú SAC','20100000045','Miraflores, Lima','987700045','contacto@disenoscreativos.pe'),
(46,'Insumos Gráficos SAC','20100000046','Breña, Lima','987700046','ventas@insumosgraficos.pe'),
(47,'Tintas del Pacífico SAC','20100000047','Cercado de Lima','987700047','ventas@tintaspacifico.pe'),
(48,'Serigrafía Profesional SAC','20100000048','Ate, Lima','987700048','ventas@serigrafiapro.pe'),
(49,'Equipos de Impresión SAC','20100000049','Lince, Lima','987700049','ventas@equiposimpresion.pe'),
(50,'Consumibles Industriales SAC','20100000050','Surquillo, Lima','987700050','ventas@consumibles.pe'),
(51,'Bordados del Sur SAC','20100000051','Villa El Salvador','987700051','ventas@bordadosdelsur.pe'),
(52,'Textil Pachacutec SAC','20100000052','Villa El Salvador','987700052','ventas@textilpachacutec.pe'),
(53,'Corporación Algodón Peruano','20100000053','La Victoria, Lima','987700053','ventas@algodonperuano.pe'),
(54,'Moda Empresarial SAC','20100000054','Ate, Lima','987700054','ventas@modaempresarial.pe'),
(55,'Importaciones Gamarra SAC','20100000055','La Victoria, Lima','987700055','ventas@gamarraimport.pe'),
(56,'Eco Merchandising SAC','20100000056','Lurín, Lima','987700056','ventas@ecomerch.pe'),
(57,'Bolsas Publicitarias SAC','20100000057','Villa María del Triunfo','987700057','ventas@bolsaspublicitarias.pe'),
(58,'Packaging Creativo SAC','20100000058','Lurín, Lima','987700058','ventas@packagingcreativo.pe'),
(59,'Empaques Corporativos SAC','20100000059','Ate, Lima','987700059','ventas@empaquescorp.pe'),
(60,'Soluciones Logísticas SAC','20100000060','Callao','987700060','ventas@solucioneslogisticas.pe'),
(61,'Agendas Ejecutivas SAC','20100000061','Lima','987700061','ventas@agendasejecutivas.pe'),
(62,'Papelería Integral SAC','20100000062','Breña, Lima','987700062','ventas@papeleriaintegral.pe'),
(63,'Cuadernos Corporativos SAC','20100000063','Lima','987700063','ventas@cuadernoscorp.pe'),
(64,'Impresiones Ejecutivas SAC','20100000064','Jesús María, Lima','987700064','ventas@impresionesejecutivas.pe'),
(65,'Gráfica Publicitaria SAC','20100000065','La Victoria, Lima','987700065','ventas@graficapublicitaria.pe'),
(66,'Tecnología Empresarial SAC','20100000066','San Isidro, Lima','987700066','ventas@tecnologiaemp.pe'),
(67,'USB Promocionales SAC','20100000067','Miraflores, Lima','987700067','ventas@usbpromocionales.pe'),
(68,'Accesorios Digitales SAC','20100000068','Surco, Lima','987700068','ventas@accesoriosdigitales.pe'),
(69,'Importadora Smart Perú SAC','20100000069','Callao','987700069','ventas@smartperu.pe'),
(70,'Tech Gifts Perú SAC','20100000070','San Borja, Lima','987700070','ventas@techgifts.pe'),
(71,'Artículos Publicitarios SAC','20100000071','Lima','987700071','ventas@artpublicitarios.pe'),
(72,'Merchandising Premium SAC','20100000072','Miraflores, Lima','987700072','ventas@merchpremium.pe'),
(73,'Regalos Corporativos SAC','20100000073','San Isidro, Lima','987700073','ventas@regaloscorp.pe'),
(74,'Marketing Promocional SAC','20100000074','Surco, Lima','987700074','ventas@marketingpromo.pe'),
(75,'Branding Perú SAC','20100000075','Lima','987700075','ventas@brandingperu.pe'),
(76,'Distribuidora Industrial SAC','20100000076','Ate, Lima','987700076','ventas@distindustrial.pe'),
(77,'Comercializadora Andina SAC','20100000077','Lurín, Lima','987700077','ventas@comandina.pe'),
(78,'Inversiones Comerciales SAC','20100000078','Villa El Salvador','987700078','ventas@invcomerciales.pe'),
(79,'Suministros Empresariales SAC','20100000079','San Juan de Miraflores','987700079','ventas@suministrosemp.pe'),
(80,'Corporación Villa Sur SAC','20100000080','Villa El Salvador','987700080','ventas@villasur.pe');

INSERT INTO Contacto_prov VALUES
(1,1,'Carlos','Ramos','986500001','cramos.prov1@gmail.com'),
(2,2,'Luis','Quispe','986500002','lquispe.prov2@gmail.com'),
(3,3,'María','Torres','986500003','mtorres.prov3@gmail.com'),
(4,4,'José','Flores','986500004','jflores.prov4@gmail.com'),
(5,5,'Ana','Vargas','986500005','avargas.prov5@gmail.com'),
(6,6,'Jorge','Paredes','986500006','jparedes.prov6@gmail.com'),
(7,7,'Rosa','Huamán','986500007','rhuaman.prov7@gmail.com'),
(8,8,'Pedro','Soto','986500008','psoto.prov8@gmail.com'),
(9,9,'Lucía','Díaz','986500009','ldiaz.prov9@gmail.com'),
(10,10,'Miguel','Castro','986500010','mcastro.prov10@gmail.com'),
(11,11,'Carmen','Salas','986500011','csalas.prov11@gmail.com'),
(12,12,'Ricardo','León','986500012','rleon.prov12@gmail.com'),
(13,13,'Sandra','Mendoza','986500013','smendoza.prov13@gmail.com'),
(14,14,'Juan','García','986500014','jgarcia.prov14@gmail.com'),
(15,15,'Patricia','Rojas','986500015','projas.prov15@gmail.com'),
(16,16,'Fernando','Silva','986500016','fsilva.prov16@gmail.com'),
(17,17,'Diana','Morales','986500017','dmorales.prov17@gmail.com'),
(18,18,'Raúl','Navarro','986500018','rnavarro.prov18@gmail.com'),
(19,19,'Elena','Cruz','986500019','ecruz.prov19@gmail.com'),
(20,20,'Víctor','López','986500020','vlopez.prov20@gmail.com'),
(21,21,'Karla','Campos','986500021','kcampos.prov21@gmail.com'),
(22,22,'Marco','Aguilar','986500022','maguilar.prov22@gmail.com'),
(23,23,'Silvia','Peña','986500023','spena.prov23@gmail.com'),
(24,24,'Daniel','Rivera','986500024','drivera.prov24@gmail.com'),
(25,25,'Mónica','Espinoza','986500025','mespinoza.prov25@gmail.com'),
(26,26,'Edgar','Valdez','986500026','evaldez.prov26@gmail.com'),
(27,27,'Paola','Benites','986500027','pbenites.prov27@gmail.com'),
(28,28,'Hugo','Alva','986500028','halva.prov28@gmail.com'),
(29,29,'Claudia','Ruiz','986500029','cruiz.prov29@gmail.com'),
(30,30,'Roberto','Palacios','986500030','rpalacios.prov30@gmail.com'),
(31,31,'Tatiana','Ortiz','986500031','tortiz.prov31@gmail.com'),
(32,32,'Kevin','Chávez','986500032','kchavez.prov32@gmail.com'),
(33,33,'Fiorella','Luna','986500033','fluna.prov33@gmail.com'),
(34,34,'Bruno','Vega','986500034','bvega.prov34@gmail.com'),
(35,35,'Milagros','Reyes','986500035','mreyes.prov35@gmail.com'),
(36,36,'Diego','Arce','986500036','darce.prov36@gmail.com'),
(37,37,'Vanessa','Mejía','986500037','vmejia.prov37@gmail.com'),
(38,38,'Renzo','Fuentes','986500038','rfuentes.prov38@gmail.com'),
(39,39,'Andrea','Cerna','986500039','acerna.prov39@gmail.com'),
(40,40,'Óscar','Villacorta','986500040','ovillacorta.prov40@gmail.com'),
(41,41,'Luis','Gonzales','986500041','lgonzales.prov41@gmail.com'),
(42,42,'Mariela','Castillo','986500042','mcastillo.prov42@gmail.com'),
(43,43,'Javier','Ramírez','986500043','jramirez.prov43@gmail.com'),
(44,44,'Patricia','Fernández','986500044','pfernandez.prov44@gmail.com'),
(45,45,'Alberto','Sánchez','986500045','asanchez.prov45@gmail.com'),
(46,46,'Verónica','Gutiérrez','986500046','vgutierrez.prov46@gmail.com'),
(47,47,'Manuel','Delgado','986500047','mdelgado.prov47@gmail.com'),
(48,48,'Roxana','Cordero','986500048','rcordero.prov48@gmail.com'),
(49,49,'César','Salazar','986500049','csalazar.prov49@gmail.com'),
(50,50,'Liliana','Vásquez','986500050','lvasquez.prov50@gmail.com'),
(51,51,'Eduardo','Carrasco','986500051','ecarrasco.prov51@gmail.com'),
(52,52,'Natalia','Mora','986500052','nmora.prov52@gmail.com'),
(53,53,'Felipe','Rentería','986500053','frenteria.prov53@gmail.com'),
(54,54,'Yolanda','Chávez','986500054','ychavez.prov54@gmail.com'),
(55,55,'Martín','Campos','986500055','mcampos.prov55@gmail.com'),
(56,56,'Pamela','Valencia','986500056','pvalencia.prov56@gmail.com'),
(57,57,'Sergio','Mendoza','986500057','smendoza.prov57@gmail.com'),
(58,58,'Karen','Espinoza','986500058','kespinoza.prov58@gmail.com'),
(59,59,'Víctor','Rojas','986500059','vrojas.prov59@gmail.com'),
(60,60,'Melissa','Navarro','986500060','mnavarro.prov60@gmail.com'),
(61,61,'Fernando','Loayza','986500061','floayza.prov61@gmail.com'),
(62,62,'Ángela','Paredes','986500062','aparedes.prov62@gmail.com'),
(63,63,'Christian','Huerta','986500063','chuerta.prov63@gmail.com'),
(64,64,'Sandra','Cisneros','986500064','scisneros.prov64@gmail.com'),
(65,65,'Diego','Villanueva','986500065','dvillanueva.prov65@gmail.com'),
(66,66,'Brenda','Linares','986500066','blinares.prov66@gmail.com'),
(67,67,'Óscar','Benavides','986500067','obenavides.prov67@gmail.com'),
(68,68,'Milagros','Torres','986500068','mtorres.prov68@gmail.com'),
(69,69,'José','Reátegui','986500069','jreategui.prov69@gmail.com'),
(70,70,'Gabriela','Velásquez','986500070','gvelasquez.prov70@gmail.com'),
(71,71,'Ricardo','Cabrera','986500071','rcabrera.prov71@gmail.com'),
(72,72,'Andrea','Herrera','986500072','aherrera.prov72@gmail.com'),
(73,73,'Kevin','Morán','986500073','kmoran.prov73@gmail.com'),
(74,74,'Lucero','Pezo','986500074','lpezo.prov74@gmail.com'),
(75,75,'Jhonatan','Vílchez','986500075','jvilchez.prov75@gmail.com'),
(76,76,'Carolina','Aguirre','986500076','caguirre.prov76@gmail.com'),
(77,77,'Renato','Meza','986500077','rmeza.prov77@gmail.com'),
(78,78,'Diana','Palomino','986500078','dpalomino.prov78@gmail.com'),
(79,79,'Alex','Ortega','986500079','aortega.prov79@gmail.com'),
(80,80,'Fiorella','Acosta','986500080','facosta.prov80@gmail.com');


INSERT INTO Producto VALUES
(1,1,1,'Polo Algodon Blanco Sublimado',25.90,'ACTIVO'),
(2,1,2,'Polo Publicitario Azul',22.50,'ACTIVO'),
(3,1,3,'Polo Premium Bordado',39.90,'ACTIVO'),
(4,1,4,'Polo DTF Negro',29.90,'ACTIVO'),
(5,1,5,'Polo Vinil Deportivo',32.90,'ACTIVO'),
(6,1,1,'Polo Cuello Redondo Blanco',24.90,'ACTIVO'),
(7,1,2,'Polo Empresarial Gris',28.90,'ACTIVO'),
(8,1,3,'Polo Ejecutivo Bordado',42.50,'ACTIVO'),

(9,2,3,'Gorra Bordada Negra',18.90,'ACTIVO'),
(10,2,3,'Gorra Bordada Azul',18.90,'ACTIVO'),
(11,2,2,'Gorra Publicitaria Roja',15.90,'ACTIVO'),
(12,2,5,'Gorra Vinil Personalizada',19.90,'ACTIVO'),
(13,2,3,'Gorra Corporativa Premium',24.90,'ACTIVO'),
(14,2,3,'Gorra Drill Bordada',22.90,'ACTIVO'),
(15,2,2,'Gorra Promocional Blanca',14.90,'ACTIVO'),
(16,2,3,'Gorra Empresarial Negra',25.90,'ACTIVO'),

(17,3,1,'Taza Blanca Sublimada',12.90,'ACTIVO'),
(18,3,1,'Taza Magica Sublimada',18.90,'ACTIVO'),
(19,3,7,'Taza UV Premium',16.90,'ACTIVO'),
(20,3,1,'Taza Corporativa Blanca',13.90,'ACTIVO'),
(21,3,1,'Taza Publicitaria Color',15.90,'ACTIVO'),
(22,3,7,'Taza Ceramica Premium',19.90,'ACTIVO'),
(23,3,1,'Taza Full Color',17.50,'ACTIVO'),
(24,3,1,'Taza Empresarial',14.90,'ACTIVO'),

(25,4,1,'Tomatodo Aluminio Blanco',24.90,'ACTIVO'),
(26,4,7,'Tomatodo UV Negro',29.90,'ACTIVO'),
(27,4,1,'Botella Deportiva Personalizada',21.90,'ACTIVO'),
(28,4,1,'Tomatodo Empresarial',26.90,'ACTIVO'),
(29,4,7,'Tomatodo Premium Metalico',34.90,'ACTIVO'),
(30,4,1,'Botella Promocional',19.90,'ACTIVO'),

(31,5,8,'Llavero Acrilico Redondo',5.90,'ACTIVO'),
(32,5,8,'Llavero Acrilico Cuadrado',5.90,'ACTIVO'),
(33,5,6,'Llavero Metalico Laser',9.90,'ACTIVO'),
(34,5,8,'Llavero Publicitario',4.90,'ACTIVO'),
(35,5,6,'Llavero Ejecutivo',12.90,'ACTIVO'),
(36,5,8,'Llavero Promocional PVC',6.90,'ACTIVO'),

(37,6,2,'Mochila Corporativa Negra',49.90,'ACTIVO'),
(38,6,3,'Mochila Bordada Premium',69.90,'ACTIVO'),
(39,6,2,'Mochila Publicitaria Azul',44.90,'ACTIVO'),
(40,6,3,'Mochila Empresarial Ejecutiva',79.90,'ACTIVO');

INSERT INTO Producto VALUES
(41,7,8,'Lapicero Ejecutivo Azul',3.50,'ACTIVO'),
(42,7,8,'Lapicero Ejecutivo Negro',3.50,'ACTIVO'),
(43,7,8,'Lapicero Publicitario Blanco',2.50,'ACTIVO'),
(44,7,8,'Lapicero Corporativo Metalico',5.90,'ACTIVO'),
(45,7,6,'Lapicero Laser Premium',7.90,'ACTIVO'),
(46,7,8,'Lapicero Promocional Rojo',2.50,'ACTIVO'),
(47,7,8,'Lapicero Publicitario Verde',2.50,'ACTIVO'),
(48,7,6,'Lapicero Ejecutivo Dorado',8.90,'ACTIVO'),

(49,8,2,'Agenda Corporativa A5',18.90,'ACTIVO'),
(50,8,2,'Agenda Empresarial 2026',22.90,'ACTIVO'),
(51,8,2,'Agenda Ejecutiva Negra',24.90,'ACTIVO'),
(52,8,2,'Agenda Publicitaria Azul',16.90,'ACTIVO'),
(53,8,10,'Agenda Premium Relieve',29.90,'ACTIVO'),
(54,8,2,'Agenda Institucional',19.90,'ACTIVO'),
(55,8,10,'Agenda Cuero Empresarial',34.90,'ACTIVO'),
(56,8,2,'Agenda Escolar Personalizada',17.90,'ACTIVO'),

(57,9,7,'USB 8GB Personalizado',18.90,'ACTIVO'),
(58,9,7,'USB 16GB Corporativo',24.90,'ACTIVO'),
(59,9,7,'USB 32GB Premium',34.90,'ACTIVO'),
(60,9,6,'USB Metalico Laser 16GB',29.90,'ACTIVO'),
(61,9,7,'USB Empresarial 8GB',19.90,'ACTIVO'),
(62,9,6,'USB Ejecutivo Metalico',36.90,'ACTIVO'),
(63,9,7,'USB Publicitario 4GB',15.90,'ACTIVO'),
(64,9,7,'USB Corporativo 64GB',49.90,'ACTIVO'),

(65,10,2,'Bolsa Ecologica Blanca',6.90,'ACTIVO'),
(66,10,2,'Bolsa Ecologica Verde',6.90,'ACTIVO'),
(67,10,2,'Bolsa Publicitaria Grande',8.90,'ACTIVO'),
(68,10,2,'Bolsa Corporativa Premium',12.90,'ACTIVO'),
(69,10,2,'Bolsa Reutilizable Azul',7.90,'ACTIVO'),
(70,10,2,'Bolsa Eco Empresarial',9.90,'ACTIVO'),
(71,10,2,'Bolsa Algodon Natural',10.90,'ACTIVO'),
(72,10,2,'Bolsa Publicitaria Economica',5.90,'ACTIVO'),

(73,1,3,'Polo Premium DryFit Bordado',44.90,'ACTIVO'),
(74,2,3,'Gorra Premium Bordado 3D',29.90,'ACTIVO'),
(75,3,1,'Taza Conica Sublimada',18.90,'ACTIVO'),
(76,4,7,'Tomatodo Acero Inoxidable',39.90,'ACTIVO'),
(77,5,6,'Llavero Metalico Premium',14.90,'ACTIVO'),
(78,6,3,'Mochila Laptop Ejecutiva',89.90,'ACTIVO'),
(79,8,10,'Agenda Gerencial Premium',39.90,'ACTIVO'),
(80,9,6,'USB Metalico 128GB Premium',69.90,'ACTIVO'),
(81,4,1,'Tomatodo Deportivo Personalizado',27.90,'ACTIVO'),
(82,4,7,'Botella Termica Acero Inoxidable',35.90,'ACTIVO'),
(83,5,8,'Llavero Madera Premium',8.90,'ACTIVO'),
(84,5,6,'Llavero Silicon Corporativo',7.90,'ACTIVO'),
(85,6,2,'Mochila Deportiva Negra',54.90,'ACTIVO'),
(86,6,3,'Mochila Viajera Premium',89.90,'ACTIVO'),
(87,6,1,'Mochila Plegable Publicitaria',39.90,'ACTIVO'),
(88,6,2,'Mochila Escolar Corporativa',49.90,'ACTIVO'),
(89,7,6,'Lapicero Metalico Grabado Laser',6.90,'ACTIVO'),
(90,10,4,'Bolsa Ecologica Personalizada DTF',7.90,'ACTIVO');


INSERT INTO Inventario VALUES
(1,1,5,30,'A1'),    
(2,2,3,25,'A2'),   
(3,3,8,20,'A3'),    
(4,4,2,25,'A4'),    
(5,5,9,20,'A5'),   
(6,6,130,30,'A6'),
(7,7,75,20,'A7'),
(8,8,60,15,'A8'),
(9,9,140,35,'B1'),
(10,10,125,30,'B2'),

(11,11,115,25,'B3'),
(12,12,105,25,'B4'),
(13,13,70,15,'B5'),
(14,14,85,20,'B6'),
(15,15,150,40,'B7'),
(16,16,95,25,'B8'),
(17,17,180,50,'C1'),
(18,18,160,45,'C2'),
(19,19,130,35,'C3'),
(20,20,145,40,'C4'),

(21,21,120,30,'C5'),
(22,22,100,25,'C6'),
(23,23,90,20,'C7'),
(24,24,110,25,'C8'),
(25,25,85,20,'D1'),
(26,26,75,15,'D2'),
(27,27,95,20,'D3'),
(28,28,80,20,'D4'),
(29,29,65,15,'D5'),
(30,30,120,30,'D6'),

(31,31,300,60,'D7'),
(32,32,280,60,'D8'),
(33,33,150,30,'E1'),
(34,34,320,70,'E2'),
(35,35,90,20,'E3'),
(36,36,250,50,'E4'),
(37,37,55,10,'E5'),
(38,38,45,10,'E6'),
(39,39,70,15,'E7'),
(40,40,40,10,'E8'),

(41,41,500,100,'F1'),
(42,42,450,90,'F2'),
(43,43,600,120,'F3'),
(44,44,300,60,'F4'),
(45,45,180,40,'F5'),
(46,46,550,110,'F6'),
(47,47,520,100,'F7'),
(48,48,160,35,'F8'),

(49,49,140,30,'G1'),
(50,50,120,25,'G2'),
(51,51,100,20,'G3'),
(52,52,180,40,'G4'),
(53,53,75,15,'G5'),
(54,54,130,30,'G6'),
(55,55,60,15,'G7'),
(56,56,170,35,'G8'),

(57,57,85,20,'H1'),
(58,58,70,15,'H2'),
(59,59,50,10,'H3'),
(60,60,65,15,'H4'),
(61,61,95,20,'H5'),
(62,62,45,10,'H6'),
(63,63,120,25,'H7'),
(64,64,35,10,'H8'),

(65,65,350,80,'I1'),
(66,66,330,75,'I2'),
(67,67,220,50,'I3'),
(68,68,180,40,'I4'),
(69,69,260,60,'I5'),
(70,70,210,50,'I6'),
(71,71,170,40,'I7'),
(72,72,400,90,'I8'),

(73,73,55,10,'J1'),
(74,74,70,15,'J2'),
(75,75,95,20,'J3'),
(76,76,40,10,'J4'),
(77,77,130,25,'J5'),
(78,78,35,10,'J6'),
(79,79,45,10,'J7'),
(80,80,20,5,'J8'),
(81,81,60,15,'D7'),
(82,82,35,10,'D8'),
(83,83,200,40,'E1'),
(84,84,180,35,'E2'),
(85,85,30,10,'E5'),
(86,86,25,5,'E6'),
(87,87,40,10,'E7'),
(88,88,35,10,'E8'),
(89,89,300,60,'F5'),
(90,90,280,50,'I5');


INSERT INTO Stock_alm VALUES
(1,1,1,120),
(2,2,2,95),
(3,3,3,80),
(4,4,4,110),
(5,5,5,90),
(6,1,6,130),
(7,2,7,75),
(8,3,8,60),
(9,4,9,140),
(10,5,10,125),

(11,1,11,115),
(12,2,12,105),
(13,3,13,70),
(14,4,14,85),
(15,5,15,150),
(16,1,16,95),
(17,2,17,180),
(18,3,18,160),
(19,4,19,130),
(20,5,20,145),

(21,1,21,120),
(22,2,22,100),
(23,3,23,90),
(24,4,24,110),
(25,5,25,85),
(26,1,26,75),
(27,2,27,95),
(28,3,28,80),
(29,4,29,65),
(30,5,30,120),

(31,1,31,300),
(32,2,32,280),
(33,3,33,150),
(34,4,34,320),
(35,5,35,90),
(36,1,36,250),
(37,2,37,55),
(38,3,38,45),
(39,4,39,70),
(40,5,40,40),

(41,1,41,500),
(42,2,42,450),
(43,3,43,600),
(44,4,44,300),
(45,5,45,180),
(46,1,46,550),
(47,2,47,520),
(48,3,48,160),
(49,4,49,140),
(50,5,50,120),

(51,1,51,100),
(52,2,52,180),
(53,3,53,75),
(54,4,54,130),
(55,5,55,60),
(56,1,56,170),
(57,2,57,85),
(58,3,58,70),
(59,4,59,50),
(60,5,60,65),

(61,1,61,95),
(62,2,62,45),
(63,3,63,120),
(64,4,64,35),
(65,5,65,350),
(66,1,66,330),
(67,2,67,220),
(68,3,68,180),
(69,4,69,260),
(70,5,70,210),

(71,1,71,170),
(72,2,72,400),
(73,3,73,55),
(74,4,74,70),
(75,5,75,95),
(76,1,76,40),
(77,2,77,130),
(78,3,78,35),
(79,4,79,45),
(80,5,80,20),
(81,1,81,60),
(82,2,82,35),
(83,3,83,200),
(84,4,84,180),
(85,5,85,30),
(86,1,86,25),
(87,2,87,40),
(88,3,88,35),
(89,4,89,300),
(90,5,90,280);


INSERT INTO Mov_invent (Id_mov, Id_prod, Tipo_mov, Cantidad, Fecha, Observacion) VALUES
(1,1,'INGRESO',200,'2024-01-10','Compra inicial de polos'),
(2,2,'INGRESO',150,'2024-01-15','Reposición de stock'),
(3,3,'SALIDA',20,'2024-02-01','Pedido cliente'),
(4,4,'INGRESO',180,'2024-02-05','Compra proveedor'),
(5,5,'SALIDA',15,'2024-02-10','Venta corporativa'),

(6,6,'INGRESO',220,'2024-03-01','Ingreso almacén'),
(7,7,'SALIDA',25,'2024-03-08','Pedido empresa'),
(8,8,'AJUSTE',5,'2024-03-12','Regularización inventario'),
(9,9,'INGRESO',250,'2024-03-20','Compra proveedor'),
(10,10,'SALIDA',30,'2024-03-25','Venta institucional'),

(11,11,'INGRESO',180,'2024-04-05','Reposición'),
(12,12,'SALIDA',18,'2024-04-12','Pedido cliente'),
(13,13,'INGRESO',120,'2024-04-18','Compra proveedor'),
(14,14,'SALIDA',12,'2024-04-22','Venta'),
(15,15,'AJUSTE',8,'2024-04-30','Conteo físico'),

(16,16,'INGRESO',170,'2024-05-03','Compra'),
(17,17,'SALIDA',35,'2024-05-10','Pedido universidad'),
(18,18,'INGRESO',200,'2024-05-15','Ingreso stock'),
(19,19,'SALIDA',22,'2024-05-20','Venta corporativa'),
(20,20,'INGRESO',190,'2024-05-25','Reposición'),

(21,21,'SALIDA',15,'2024-06-05','Pedido cliente'),
(22,22,'INGRESO',140,'2024-06-10','Compra proveedor'),
(23,23,'SALIDA',18,'2024-06-15','Venta'),
(24,24,'INGRESO',160,'2024-06-20','Ingreso almacén'),
(25,25,'AJUSTE',10,'2024-06-25','Regularización'),

(26,26,'INGRESO',130,'2024-07-01','Compra'),
(27,27,'SALIDA',20,'2024-07-08','Pedido'),
(28,28,'INGRESO',140,'2024-07-15','Reposición'),
(29,29,'SALIDA',12,'2024-07-20','Venta'),
(30,30,'INGRESO',180,'2024-07-28','Compra'),

(31,31,'INGRESO',500,'2024-08-02','Compra masiva'),
(32,32,'SALIDA',50,'2024-08-08','Campaña promocional'),
(33,33,'INGRESO',250,'2024-08-15','Ingreso almacén'),
(34,34,'SALIDA',35,'2024-08-20','Pedido cliente'),
(35,35,'AJUSTE',5,'2024-08-28','Conteo físico'),

(36,36,'INGRESO',300,'2024-09-05','Compra'),
(37,37,'SALIDA',10,'2024-09-10','Venta'),
(38,38,'INGRESO',100,'2024-09-15','Reposición'),
(39,39,'SALIDA',15,'2024-09-20','Pedido'),
(40,40,'INGRESO',120,'2024-09-25','Compra proveedor'),

(41,41,'INGRESO',700,'2025-01-05','Ingreso anual'),
(42,42,'SALIDA',80,'2025-01-10','Pedido institucional'),
(43,43,'INGRESO',800,'2025-01-15','Compra proveedor'),
(44,44,'SALIDA',50,'2025-01-20','Venta'),
(45,45,'AJUSTE',12,'2025-01-25','Regularización'),

(46,46,'INGRESO',650,'2025-02-01','Reposición'),
(47,47,'SALIDA',75,'2025-02-08','Pedido empresa'),
(48,48,'INGRESO',220,'2025-02-15','Compra'),
(49,49,'SALIDA',20,'2025-02-22','Venta'),
(50,50,'INGRESO',180,'2025-02-28','Ingreso almacén'),

(51,51,'INGRESO',150,'2025-03-05','Compra'),
(52,52,'SALIDA',25,'2025-03-12','Pedido'),
(53,53,'INGRESO',110,'2025-03-18','Reposición'),
(54,54,'SALIDA',18,'2025-03-22','Venta'),
(55,55,'AJUSTE',4,'2025-03-29','Conteo físico'),

(56,56,'INGRESO',200,'2025-04-03','Compra'),
(57,57,'SALIDA',15,'2025-04-08','Pedido'),
(58,58,'INGRESO',120,'2025-04-15','Ingreso stock'),
(59,59,'SALIDA',8,'2025-04-20','Venta'),
(60,60,'INGRESO',140,'2025-04-28','Compra'),

(61,61,'INGRESO',180,'2026-01-05','Compra anual'),
(62,62,'SALIDA',12,'2026-01-10','Pedido cliente'),
(63,63,'INGRESO',220,'2026-01-15','Reposición'),
(64,64,'SALIDA',10,'2026-01-20','Venta'),
(65,65,'INGRESO',500,'2026-02-01','Ingreso almacén'),

(66,66,'SALIDA',40,'2026-02-08','Pedido corporativo'),
(67,67,'INGRESO',350,'2026-02-15','Compra proveedor'),
(68,68,'SALIDA',25,'2026-02-20','Venta'),
(69,69,'INGRESO',300,'2026-03-01','Reposición'),
(70,70,'SALIDA',30,'2026-03-05','Pedido'),

(71,71,'INGRESO',250,'2026-03-10','Compra'),
(72,72,'SALIDA',45,'2026-03-15','Venta institucional'),
(73,73,'INGRESO',100,'2026-04-01','Ingreso stock'),
(74,74,'SALIDA',15,'2026-04-05','Pedido'),
(75,75,'AJUSTE',6,'2026-04-10','Regularización'),

(76,76,'INGRESO',80,'2026-04-15','Compra'),
(77,77,'SALIDA',20,'2026-05-01','Venta'),
(78,78,'INGRESO',70,'2026-05-05','Reposición'),
(79,79,'SALIDA',10,'2026-05-10','Pedido cliente'),
(80,80,'INGRESO',50,'2026-05-15','Ingreso almacén');


INSERT INTO Pedido VALUES
(1,1,4,'2025-01-05','2025-01-10','ENTREGADO','Pedido de polos promocionales'),
(2,1,4,'2025-02-08','2025-02-15','ENTREGADO','Material para academia'),
(3,1,4,'2025-03-12','2025-03-22','ENTREGADO','Merchandising institucional'),
(4,1,3,'2025-04-15','2025-04-25','PROCESADO','Polos para evento'),

(5,5,4,'2025-01-18','2025-01-28','ENTREGADO','Tazas corporativas'),
(6,5,4,'2025-02-22','2025-03-01','ENTREGADO','Gorras personalizadas'),
(7,5,4,'2025-03-25','2025-04-02','ENTREGADO','Pedido promocional'),
(8,5,3,'2025-04-28','2025-05-05','PROCESADO','Material publicitario'),

(9,10,4,'2025-02-01','2025-02-08','ENTREGADO','Polos para campaña'),
(10,10,4,'2025-03-03','2025-03-12','ENTREGADO','Tomatodos corporativos'),
(11,10,4,'2025-04-05','2025-04-12','ENTREGADO','Pedido institucional'),
(12,10,4,'2025-05-08','2025-05-15','ENTREGADO','Material promocional'),

(13,15,4,'2025-02-10','2025-02-18','ENTREGADO','Llaveros corporativos'),
(14,15,3,'2025-03-12','2025-03-22','PROCESADO','Polos escolares'),
(15,15,4,'2025-04-15','2025-04-25','ENTREGADO','Merchandising empresarial'),
(16,15,4,'2025-05-18','2025-05-28','ENTREGADO','Agendas corporativas'),

(17,20,4,'2025-02-20','2025-03-01','ENTREGADO','Tomatodos promocionales'),
(18,20,4,'2025-03-25','2025-04-05','ENTREGADO','Gorras para campaña'),
(19,20,3,'2025-04-01','2025-04-10','PROCESADO','Material publicitario'),
(20,20,4,'2025-05-03','2025-05-12','ENTREGADO','Pedido corporativo'),

(21,25,4,'2025-03-05','2025-03-15','ENTREGADO','Polos institucionales'),
(22,25,4,'2025-04-08','2025-04-18','ENTREGADO','Tazas personalizadas'),
(23,25,4,'2025-05-10','2025-05-20','ENTREGADO','USB corporativos'),
(24,25,3,'2025-06-12','2025-06-22','PROCESADO','Material académico'),

(25,30,4,'2025-03-15','2025-03-25','ENTREGADO','Pedido promocional'),
(26,30,4,'2025-04-18','2025-04-28','ENTREGADO','Polos restaurante'),
(27,30,4,'2025-05-20','2025-05-30','ENTREGADO','Gorras publicitarias'),
(28,30,4,'2025-06-22','2025-07-02','ENTREGADO','Material ferretería'),

(29,35,3,'2025-03-25','2025-04-05','PROCESADO','Tomatodos médicos'),
(30,35,4,'2025-04-28','2025-05-08','ENTREGADO','Pedido odontológico'),
(31,35,4,'2025-06-01','2025-06-10','ENTREGADO','Polos escolares'),
(32,35,4,'2025-07-03','2025-07-12','ENTREGADO','Material institucional'),

(33,40,4,'2025-04-05','2025-04-15','ENTREGADO','Pedido académico'),
(34,40,4,'2025-05-08','2025-05-18','ENTREGADO','USB promocionales'),
(35,40,3,'2025-06-10','2025-06-20','PROCESADO','Agendas universitarias'),
(36,40,4,'2025-07-12','2025-07-22','ENTREGADO','Pedido corporativo'),

(37,45,4,'2025-04-15','2025-04-25','ENTREGADO','Material financiero'),
(38,45,4,'2025-05-18','2025-05-28','ENTREGADO','Polos promocionales'),
(39,45,4,'2025-06-20','2025-06-30','ENTREGADO','Tazas corporativas'),
(40,45,3,'2025-07-22','2025-08-02','PROCESADO','Pedido institucional'),

(41,50,4,'2025-05-01','2025-05-10','ENTREGADO','Material veterinario'),
(42,50,4,'2025-06-03','2025-06-12','ENTREGADO','Material farmacéutico'),
(43,50,4,'2025-07-05','2025-07-15','ENTREGADO','Publicidad restaurante'),
(44,50,4,'2025-08-08','2025-08-18','ENTREGADO','Pedido hotelero'),

(45,55,3,'2025-05-10','2025-05-20','PROCESADO','Merchandising gimnasio'),
(46,55,4,'2025-06-12','2025-06-22','ENTREGADO','Polos escolares'),
(47,55,4,'2025-07-15','2025-07-25','ENTREGADO','Material educativo'),
(48,55,4,'2025-08-18','2025-08-28','ENTREGADO','Pedido institucional'),

(49,60,4,'2025-05-20','2025-05-30','ENTREGADO','Material transporte'),
(50,60,3,'2025-06-22','2025-07-02','PROCESADO','Pedido constructora'),
(51,60,4,'2026-01-05','2026-01-15','ENTREGADO','Polos textiles'),
(52,60,4,'2026-02-08','2026-02-18','ENTREGADO','Material gráfico'),

(53,65,4,'2026-01-10','2026-01-20','ENTREGADO','Pedido comercial'),
(54,65,4,'2026-02-12','2026-02-22','ENTREGADO','Publicidad agroindustrial'),
(55,65,3,'2026-03-15','2026-03-25','PROCESADO','Pedido corporativo'),
(56,65,4,'2026-04-18','2026-04-28','ENTREGADO','Material empresarial'),

(57,70,4,'2026-01-20','2026-01-30','ENTREGADO','Merchandising asociación'),
(58,70,4,'2026-02-22','2026-03-01','ENTREGADO','Pedido corporativo'),
(59,70,4,'2026-03-25','2026-04-05','ENTREGADO','Material fundación'),
(60,70,3,'2026-04-28','2026-05-08','PROCESADO','Pedido ONG'),

(61,75,4,'2026-02-01','2026-02-10','ENTREGADO','Polos escolares'),
(62,75,4,'2026-03-03','2026-03-12','ENTREGADO','Material educativo'),
(63,75,4,'2026-04-05','2026-04-15','ENTREGADO','Pedido academia'),
(64,75,4,'2026-05-08','2026-05-18','ENTREGADO','Material tecnológico'),

(65,80,3,'2026-02-10','2026-02-20','PROCESADO','Pedido consultoría'),
(66,80,4,'2026-03-12','2026-03-22','ENTREGADO','Material minero'),
(67,80,4,'2026-04-15','2026-04-25','ENTREGADO','Publicidad corporativa'),
(68,80,4,'2026-05-18','2026-05-28','ENTREGADO','Pedido cooperativa'),

(69,3,4,'2026-02-20','2026-03-02','ENTREGADO','Material promocional'),
(70,3,3,'2026-03-22','2026-04-05','PROCESADO','Pedido educativo'),

(71,8,4,'2026-03-01','2026-03-10','ENTREGADO','Evento corporativo'),
(72,8,4,'2026-04-03','2026-04-12','ENTREGADO','Producción publicitaria'),

(73,12,4,'2026-03-05','2026-03-15','ENTREGADO','Material académico'),
(74,12,4,'2026-04-08','2026-04-18','ENTREGADO','Material médico'),

(75,18,3,'2026-03-10','2026-03-20','PROCESADO','Pedido distribuidora'),
(76,18,4,'2026-05-12','2026-05-22','ENTREGADO','Polos escolares'),

(77,22,4,'2026-03-15','2026-03-25','ENTREGADO','Material constructora'),
(78,22,4,'2026-06-18','2026-06-28','ENTREGADO','Pedido corporativo'),

(79,28,2,'2026-03-20','2026-03-30','ADMITIDO','Pedido deportivo'),
(80,28,1,'2026-03-25','2026-04-05','PENDIENTE','Pedido empresarial');


INSERT INTO Det_pedido VALUES
(1,1,1,20,518.00),
(2,2,2,15,337.50),
(3,3,3,10,399.00),
(4,4,4,12,358.80),
(5,5,5,8,263.20),
(6,6,6,20,498.00),
(7,7,7,10,289.00),
(8,8,8,5,212.50),
(9,9,9,25,472.50),
(10,10,10,20,378.00),

(11,11,11,15,238.50),
(12,12,12,18,358.20),
(13,13,13,10,249.00),
(14,14,14,12,274.80),
(15,15,15,20,298.00),
(16,16,16,15,388.50),
(17,17,17,30,387.00),
(18,18,18,20,378.00),
(19,19,19,15,253.50),
(20,20,20,18,250.20),

(21,21,21,25,397.50),
(22,22,22,15,298.50),
(23,23,23,10,175.00),
(24,24,24,20,298.00),
(25,25,25,12,298.80),
(26,26,26,10,299.00),
(27,27,27,15,328.50),
(28,28,28,12,322.80),
(29,29,29,8,279.20),
(30,30,30,20,398.00),

(31,31,31,50,295.00),
(32,32,32,40,236.00),
(33,33,33,20,198.00),
(34,34,34,60,294.00),
(35,35,35,15,193.50),
(36,36,36,30,207.00),
(37,37,37,8,399.20),
(38,38,38,5,349.50),
(39,39,39,10,449.00),
(40,40,40,4,319.60),

(41,41,41,100,350.00),
(42,42,42,80,280.00),
(43,43,43,120,300.00),
(44,44,44,50,295.00),
(45,45,45,20,158.00),
(46,46,46,100,250.00),
(47,47,47,90,225.00),
(48,48,48,25,222.50),
(49,49,49,15,283.50),
(50,50,50,12,274.80),

(51,51,51,10,249.00),
(52,52,52,20,338.00),
(53,53,53,5,149.50),
(54,54,54,15,298.50),
(55,55,55,3,104.70),
(56,56,56,20,358.00),
(57,57,57,10,189.00),
(58,58,58,8,199.20),
(59,59,59,5,174.50),
(60,60,60,6,179.40),

(61,61,61,10,199.00),
(62,62,62,5,184.50),
(63,63,63,15,238.50),
(64,64,64,3,149.70),
(65,65,65,50,345.00),
(66,66,66,40,276.00),
(67,67,67,30,267.00),
(68,68,68,20,258.00),
(69,69,69,35,276.50),
(70,70,70,25,247.50),

(71,71,71,15,163.50),
(72,72,72,50,295.00),
(73,73,73,10,449.00),
(74,74,74,8,239.20),
(75,75,75,12,226.80),
(76,76,76,5,199.50),
(77,77,77,15,223.50),
(78,78,78,3,269.70),
(79,79,79,4,159.60),
(80,80,80,2,139.80),
(81,2,9,10,189.00),
(82,3,11,10,159.00),
(83,4,17,12,154.80),
(84,5,18,15,283.50),
(85,6,19,5,84.50),
(86,7,8,7,297.50),
(87,8,22,15,298.50),
(88,9,23,5,87.50),
(89,10,1,8,207.20),
(90,15,25,10,249.00);


INSERT INTO Despacho VALUES
(1,1,1,3,'2025-01-08','Sector 2 Grupo 15 Mz C Lt 8 VES','Juan Perez','ENTREGADO'),
(2,2,2,3,'2025-01-12','Av Revolucion 1250 VES','Luis Ramos','ENTREGADO'),
(3,3,3,3,'2025-01-18','Av El Sol 456 VMT','Carlos Diaz','ENTREGADO'),
(4,4,4,2,'2025-01-22','Jr Los Cedros 221 SJM','Ana Torres','EN RUTA'),
(5,5,5,3,'2025-01-26','Av Pachacutec 890 VES','Miguel Flores','ENTREGADO'),

(6,6,6,3,'2025-01-28','Sector 3 Grupo 7 VES','Juan Perez','ENTREGADO'),
(7,7,7,3,'2025-02-01','Av Lima 450 Chorrillos','Luis Ramos','ENTREGADO'),
(8,8,8,2,'2025-02-04','Av Separadora Industrial 115 Ate','Carlos Diaz','EN RUTA'),
(9,9,9,3,'2025-02-07','Av Universitaria 3250 SMP','Ana Torres','ENTREGADO'),
(10,10,10,3,'2025-02-09','Av Aviacion 2210 La Victoria','Miguel Flores','ENTREGADO'),

(11,11,11,3,'2025-02-12','Av Grau 560 Cercado','Juan Perez','ENTREGADO'),
(12,12,12,3,'2025-02-14','Jr Tacna 890 Breña','Luis Ramos','ENTREGADO'),
(13,13,13,3,'2025-02-17','Av Angamos 1430 Surquillo','Carlos Diaz','ENTREGADO'),
(14,14,14,2,'2025-02-20','Av Benavides 500 Surco','Ana Torres','EN RUTA'),
(15,15,15,3,'2025-02-23','Av Larco 120 Miraflores','Miguel Flores','ENTREGADO'),

(16,16,16,3,'2025-02-26','Av Javier Prado 2450 San Isidro','Juan Perez','ENTREGADO'),
(17,17,17,3,'2025-02-28','Av Brasil 330 Pueblo Libre','Luis Ramos','ENTREGADO'),
(18,18,18,3,'2025-03-03','Av Marina 1800 San Miguel','Carlos Diaz','ENTREGADO'),
(19,19,19,2,'2025-03-08','Av Colonial 2200 Callao','Ana Torres','EN RUTA'),
(20,20,20,3,'2025-03-10','Av Faucett 1450 Callao','Miguel Flores','ENTREGADO'),

(21,21,21,3,'2025-03-13','Sector 1 Grupo 22 VES','Juan Perez','ENTREGADO'),
(22,22,22,3,'2025-03-16','Av Central 440 VES','Luis Ramos','ENTREGADO'),
(23,23,23,3,'2025-03-18','Av Los Heroes 1520 SJM','Carlos Diaz','ENTREGADO'),
(24,24,24,2,'2025-03-21','Av Caminos del Inca 990 Surco','Ana Torres','EN RUTA'),
(25,25,25,3,'2025-03-24','Av Guardia Civil 450 San Borja','Miguel Flores','ENTREGADO'),

(26,26,26,3,'2025-03-27','Av Canada 1800 La Victoria','Juan Perez','ENTREGADO'),
(27,27,27,3,'2025-03-29','Jr Huallaga 500 Cercado','Luis Ramos','ENTREGADO'),
(28,28,28,3,'2025-04-01','Av Abancay 1200 Cercado','Carlos Diaz','ENTREGADO'),
(29,29,29,2,'2025-04-04','Av Argentina 890 Cercado','Ana Torres','EN RUTA'),
(30,30,30,3,'2025-04-07','Av Tomas Marsano 3300 Surco','Miguel Flores','ENTREGADO'),

(31,31,31,3,'2025-04-09','Sector 4 Grupo 5 VES','Juan Perez','ENTREGADO'),
(32,32,32,3,'2025-04-11','Av El Triunfo 760 VES','Luis Ramos','ENTREGADO'),
(33,33,33,3,'2025-04-14','Av Micaela Bastidas 980 VES','Carlos Diaz','ENTREGADO'),
(34,34,34,3,'2025-04-17','Av San Juan 2100 SJM','Ana Torres','ENTREGADO'),
(35,35,35,2,'2025-04-20','Av Próceres 1900 SJL','Miguel Flores','EN RUTA'),

(36,36,36,3,'2025-04-22','Av Metropolitana 760 Comas','Juan Perez','ENTREGADO'),
(37,37,37,3,'2025-04-25','Av Tupac Amaru 5500 Comas','Luis Ramos','ENTREGADO'),
(38,38,38,3,'2025-04-27','Av Naranjal 1100 Los Olivos','Carlos Diaz','ENTREGADO'),
(39,39,39,3,'2025-04-29','Av Antunez de Mayolo 1700 Los Olivos','Ana Torres','ENTREGADO'),
(40,40,40,2,'2025-05-01','Av Alfredo Mendiola 4200 Independencia','Miguel Flores','EN RUTA'),

(41,41,41,3,'2025-05-05','Av Universitaria 5400 Los Olivos','Juan Perez','ENTREGADO'),
(42,42,42,3,'2025-05-08','Av Trapiche 1300 Comas','Luis Ramos','ENTREGADO'),
(43,43,43,3,'2025-05-11','Av Los Alisos 900 SMP','Carlos Diaz','ENTREGADO'),
(44,44,44,3,'2025-05-14','Av Peru 2100 SMP','Ana Torres','ENTREGADO'),
(45,45,45,2,'2025-05-17','Av Canta Callao 3500 SMP','Miguel Flores','EN RUTA'),

(46,46,46,3,'2025-05-20','Sector 5 Grupo 10 VES','Juan Perez','ENTREGADO'),
(47,47,47,3,'2025-05-23','Av Revolucion 980 VES','Luis Ramos','ENTREGADO'),
(48,48,48,3,'2025-05-26','Av Separadora Agroindustrial 700 VES','Carlos Diaz','ENTREGADO'),
(49,49,49,3,'2025-05-29','Av Pastor Sevilla 1200 VES','Ana Torres','ENTREGADO'),
(50,50,50,2,'2025-06-02','Av Mariano Pastor Sevilla 1800 VES','Miguel Flores','EN RUTA'),

(51,51,1,3,'2026-01-10','Sector 2 Grupo 15 VES','Juan Perez','ENTREGADO'),
(52,52,2,3,'2026-01-13','Av Revolucion 1250 VES','Luis Ramos','ENTREGADO'),
(53,53,3,3,'2026-01-17','Av El Sol 456 VMT','Carlos Diaz','ENTREGADO'),
(54,54,4,3,'2026-01-21','Jr Los Cedros 221 SJM','Ana Torres','ENTREGADO'),
(55,55,5,2,'2026-01-24','Av Pachacutec 890 VES','Miguel Flores','EN RUTA'),

(56,56,6,3,'2026-01-28','Sector 3 Grupo 7 VES','Juan Perez','ENTREGADO'),
(57,57,7,3,'2026-01-31','Av Lima 450 Chorrillos','Luis Ramos','ENTREGADO'),
(58,58,8,3,'2026-02-03','Av Separadora Industrial 115 Ate','Carlos Diaz','ENTREGADO'),
(59,59,9,3,'2026-02-06','Av Universitaria 3250 SMP','Ana Torres','ENTREGADO'),
(60,60,10,2,'2026-02-09','Av Aviacion 2210 La Victoria','Miguel Flores','EN RUTA'),

(61,61,11,3,'2026-02-12','Av Grau 560 Cercado','Juan Perez','ENTREGADO'),
(62,62,12,3,'2026-02-15','Jr Tacna 890 Breña','Luis Ramos','ENTREGADO'),
(63,63,13,3,'2026-02-18','Av Angamos 1430 Surquillo','Carlos Diaz','ENTREGADO'),
(64,64,14,3,'2026-02-21','Av Benavides 500 Surco','Ana Torres','ENTREGADO'),
(65,65,15,2,'2026-02-24','Av Larco 120 Miraflores','Miguel Flores','EN RUTA'),

(66,66,16,3,'2026-02-27','Av Javier Prado 2450 San Isidro','Juan Perez','ENTREGADO'),
(67,67,17,3,'2026-03-02','Av Brasil 330 Pueblo Libre','Luis Ramos','ENTREGADO'),
(68,68,18,3,'2026-03-05','Av Marina 1800 San Miguel','Carlos Diaz','ENTREGADO'),
(69,69,19,3,'2026-03-08','Av Colonial 2200 Callao','Ana Torres','ENTREGADO'),
(70,70,20,2,'2026-03-11','Av Faucett 1450 Callao','Miguel Flores','EN RUTA'),

(71,71,21,3,'2026-03-14','Sector 1 Grupo 22 VES','Juan Perez','ENTREGADO'),
(72,72,22,3,'2026-03-17','Av Central 440 VES','Luis Ramos','ENTREGADO'),
(73,73,23,3,'2026-03-20','Av Los Heroes 1520 SJM','Carlos Diaz','ENTREGADO'),
(74,74,24,3,'2026-03-23','Av Caminos del Inca 990 Surco','Ana Torres','ENTREGADO'),
(75,75,25,2,'2026-03-26','Av Guardia Civil 450 San Borja','Miguel Flores','EN RUTA'),

(76,76,26,1,'2026-03-29','Av Canada 1800 La Victoria','Juan Perez','EN ALMACEN'),
(77,77,27,1,'2026-04-01','Jr Huallaga 500 Cercado','Luis Ramos','EN ALMACEN'),
(78,78,28,1,'2026-04-03','Av Abancay 1200 Cercado','Carlos Diaz','EN ALMACEN'),
(79,79,29,2,'2026-04-05','Av Argentina 890 Cercado','Ana Torres','EN RUTA'),
(80,80,30,1,'2026-04-08','Av Tomas Marsano 3300 Surco','Miguel Flores','EN ALMACEN');





INSERT INTO Comprobante VALUES
(1,1,2,'FACTURA',0.18,'2025-01-05',611.24,'PAGADO'),
(2,2,2,'BOLETA',0.18,'2025-01-08',398.25,'PAGADO'),
(3,3,2,'FACTURA',0.18,'2025-01-12',470.82,'PAGADO'),
(4,4,1,'FACTURA',0.18,'2025-01-15',423.38,'EMITIDO'),
(5,5,2,'BOLETA',0.18,'2025-01-18',310.58,'PAGADO'),

(6,6,2,'FACTURA',0.18,'2025-01-22',587.64,'PAGADO'),
(7,7,2,'BOLETA',0.18,'2025-01-25',341.02,'PAGADO'),
(8,8,1,'FACTURA',0.18,'2025-01-28',250.75,'EMITIDO'),
(9,9,2,'FACTURA',0.18,'2025-02-01',557.55,'PAGADO'),
(10,10,2,'BOLETA',0.18,'2025-02-03',446.04,'PAGADO'),

(11,11,2,'FACTURA',0.18,'2025-02-05',281.43,'PAGADO'),
(12,12,2,'BOLETA',0.18,'2025-02-08',422.68,'PAGADO'),
(13,13,2,'FACTURA',0.18,'2025-02-10',293.82,'PAGADO'),
(14,14,1,'FACTURA',0.18,'2025-02-12',324.26,'EMITIDO'),
(15,15,2,'BOLETA',0.18,'2025-02-15',351.64,'PAGADO'),

(16,16,2,'FACTURA',0.18,'2025-02-18',458.43,'PAGADO'),
(17,17,2,'BOLETA',0.18,'2025-02-20',456.66,'PAGADO'),
(18,18,2,'FACTURA',0.18,'2025-02-25',446.04,'PAGADO'),
(19,19,1,'FACTURA',0.18,'2025-03-01',299.13,'EMITIDO'),
(20,20,2,'BOLETA',0.18,'2025-03-03',295.24,'PAGADO'),

(21,21,2,'FACTURA',0.18,'2025-03-05',469.05,'PAGADO'),
(22,22,2,'BOLETA',0.18,'2025-03-08',352.23,'PAGADO'),
(23,23,2,'FACTURA',0.18,'2025-03-10',206.50,'PAGADO'),
(24,24,1,'FACTURA',0.18,'2025-03-12',351.64,'EMITIDO'),
(25,25,2,'BOLETA',0.18,'2025-03-15',352.58,'PAGADO'),

(26,26,2,'FACTURA',0.18,'2025-03-18',352.82,'PAGADO'),
(27,27,2,'BOLETA',0.18,'2025-03-20',387.63,'PAGADO'),
(28,28,2,'FACTURA',0.18,'2025-03-22',380.90,'PAGADO'),
(29,29,1,'FACTURA',0.18,'2025-03-25',329.46,'EMITIDO'),
(30,30,2,'BOLETA',0.18,'2025-03-28',469.64,'PAGADO'),

(31,31,2,'FACTURA',0.18,'2025-04-01',348.10,'PAGADO'),
(32,32,2,'BOLETA',0.18,'2025-04-03',278.48,'PAGADO'),
(33,33,2,'FACTURA',0.18,'2025-04-05',233.64,'PAGADO'),
(34,34,2,'FACTURA',0.18,'2025-04-08',346.92,'PAGADO'),
(35,35,1,'BOLETA',0.18,'2025-04-10',228.33,'EMITIDO'),

(36,36,2,'FACTURA',0.18,'2025-04-12',244.26,'PAGADO'),
(37,37,2,'FACTURA',0.18,'2025-04-15',471.06,'PAGADO'),
(38,38,2,'BOLETA',0.18,'2025-04-18',412.41,'PAGADO'),
(39,39,2,'FACTURA',0.18,'2025-04-20',529.82,'PAGADO'),
(40,40,1,'BOLETA',0.18,'2025-04-22',377.13,'EMITIDO'),

(41,41,2,'FACTURA',0.18,'2025-05-01',413.00,'PAGADO'),
(42,42,2,'BOLETA',0.18,'2025-05-03',330.40,'PAGADO'),
(43,43,2,'FACTURA',0.18,'2025-05-05',354.00,'PAGADO'),
(44,44,2,'FACTURA',0.18,'2025-05-08',348.10,'PAGADO'),
(45,45,1,'BOLETA',0.18,'2025-05-10',186.44,'EMITIDO'),

(46,46,2,'FACTURA',0.18,'2025-05-12',295.00,'PAGADO'),
(47,47,2,'FACTURA',0.18,'2025-05-15',265.50,'PAGADO'),
(48,48,2,'BOLETA',0.18,'2025-05-18',262.55,'PAGADO'),
(49,49,2,'FACTURA',0.18,'2025-05-20',334.53,'PAGADO'),
(50,50,1,'BOLETA',0.18,'2025-05-22',324.26,'EMITIDO'),

(51,51,2,'FACTURA',0.18,'2026-01-05',293.82,'PAGADO'),
(52,52,2,'BOLETA',0.18,'2026-01-08',398.84,'PAGADO'),
(53,53,2,'FACTURA',0.18,'2026-01-10',176.41,'PAGADO'),
(54,54,2,'FACTURA',0.18,'2026-01-12',352.23,'PAGADO'),
(55,55,1,'BOLETA',0.18,'2026-01-15',123.55,'EMITIDO'),

(56,56,2,'FACTURA',0.18,'2026-01-18',422.44,'PAGADO'),
(57,57,2,'FACTURA',0.18,'2026-01-20',223.02,'PAGADO'),
(58,58,2,'BOLETA',0.18,'2026-01-22',235.06,'PAGADO'),
(59,59,2,'FACTURA',0.18,'2026-01-25',205.91,'PAGADO'),
(60,60,1,'BOLETA',0.18,'2026-01-28',211.69,'EMITIDO'),

(61,61,2,'FACTURA',0.18,'2026-02-01',234.82,'PAGADO'),
(62,62,2,'BOLETA',0.18,'2026-02-03',217.71,'PAGADO'),
(63,63,2,'FACTURA',0.18,'2026-02-05',281.43,'PAGADO'),
(64,64,2,'FACTURA',0.18,'2026-02-08',176.65,'PAGADO'),
(65,65,1,'BOLETA',0.18,'2026-02-10',407.10,'EMITIDO'),

(66,66,2,'FACTURA',0.18,'2026-02-12',325.68,'PAGADO'),
(67,67,2,'FACTURA',0.18,'2026-02-15',315.06,'PAGADO'),
(68,68,2,'BOLETA',0.18,'2026-02-18',304.44,'PAGADO'),
(69,69,2,'FACTURA',0.18,'2026-02-20',326.27,'PAGADO'),
(70,70,1,'BOLETA',0.18,'2026-02-22',292.05,'EMITIDO'),

(71,71,2,'FACTURA',0.18,'2026-03-01',192.93,'PAGADO'),
(72,72,2,'FACTURA',0.18,'2026-03-03',348.10,'PAGADO'),
(73,73,2,'BOLETA',0.18,'2026-03-05',529.82,'PAGADO'),
(74,74,2,'FACTURA',0.18,'2026-03-08',282.26,'PAGADO'),
(75,75,1,'BOLETA',0.18,'2026-03-10',267.62,'EMITIDO'),

(76,76,2,'FACTURA',0.18,'2026-03-12',235.41,'PAGADO'),
(77,77,2,'FACTURA',0.18,'2026-03-15',263.73,'PAGADO'),
(78,78,2,'BOLETA',0.18,'2026-03-18',318.25,'PAGADO'),
(79,79,1,'FACTURA',0.18,'2026-03-20',188.33,'EMITIDO'),
(80,80,1,'BOLETA',0.18,'2026-03-25',164.96,'EMITIDO');


INSERT INTO Pago VALUES
(1,1,4,'2025-01-06',611.24),
(2,2,2,'2025-01-09',398.25),
(3,3,5,'2025-01-13',470.82),
(4,4,4,'2025-01-16',423.38),
(5,5,2,'2025-01-19',310.58),

(6,6,5,'2025-01-23',587.64),
(7,7,1,'2025-01-26',341.02),
(8,8,4,'2025-01-29',250.75),
(9,9,2,'2025-02-02',557.55),
(10,10,5,'2025-02-04',446.04),

(11,11,3,'2025-02-06',281.43),
(12,12,2,'2025-02-09',422.68),
(13,13,4,'2025-02-11',293.82),
(14,14,5,'2025-02-13',324.26),
(15,15,2,'2025-02-16',351.64),

(16,16,4,'2025-02-19',458.43),
(17,17,3,'2025-02-21',456.66),
(18,18,2,'2025-02-26',446.04),
(19,19,4,'2025-03-02',299.13),
(20,20,5,'2025-03-04',295.24),

(21,21,2,'2025-03-06',469.05),
(22,22,1,'2025-03-09',352.23),
(23,23,4,'2025-03-11',206.50),
(24,24,5,'2025-03-13',351.64),
(25,25,2,'2025-03-16',352.58),

(26,26,3,'2025-03-19',352.82),
(27,27,4,'2025-03-21',387.63),
(28,28,5,'2025-03-23',380.90),
(29,29,2,'2025-03-26',329.46),
(30,30,4,'2025-03-29',469.64),

(31,31,5,'2025-04-02',348.10),
(32,32,2,'2025-04-04',278.48),
(33,33,3,'2025-04-06',233.64),
(34,34,4,'2025-04-09',346.92),
(35,35,5,'2025-04-11',228.33),

(36,36,2,'2025-04-13',244.26),
(37,37,4,'2025-04-16',471.06),
(38,38,5,'2025-04-19',412.41),
(39,39,2,'2025-04-21',529.82),
(40,40,3,'2025-04-23',377.13),

(41,41,4,'2025-05-02',413.00),
(42,42,2,'2025-05-04',330.40),
(43,43,5,'2025-05-06',354.00),
(44,44,4,'2025-05-09',348.10),
(45,45,2,'2025-05-11',186.44),

(46,46,3,'2025-05-13',295.00),
(47,47,4,'2025-05-16',265.50),
(48,48,5,'2025-05-19',262.55),
(49,49,2,'2025-05-21',334.53),
(50,50,4,'2025-05-23',324.26),

(51,51,5,'2026-01-06',293.82),
(52,52,2,'2026-01-09',398.84),
(53,53,3,'2026-01-11',176.41),
(54,54,4,'2026-01-13',352.23),
(55,55,2,'2026-01-16',123.55),

(56,56,5,'2026-01-19',422.44),
(57,57,4,'2026-01-21',223.02),
(58,58,2,'2026-01-23',235.06),
(59,59,3,'2026-01-26',205.91),
(60,60,4,'2026-01-29',211.69),

(61,61,5,'2026-02-02',234.82),
(62,62,2,'2026-02-04',217.71),
(63,63,4,'2026-02-06',281.43),
(64,64,3,'2026-02-09',176.65),
(65,65,2,'2026-02-11',407.10),

(66,66,5,'2026-02-13',325.68),
(67,67,4,'2026-02-16',315.06),
(68,68,2,'2026-02-19',304.44),
(69,69,3,'2026-02-21',326.27),
(70,70,4,'2026-02-23',292.05),

(71,71,5,'2026-03-02',192.93),
(72,72,2,'2026-03-04',348.10),
(73,73,4,'2026-03-06',529.82),
(74,74,3,'2026-03-09',282.26),
(75,75,2,'2026-03-11',267.62),

(76,76,5,'2026-03-13',235.41),
(77,77,4,'2026-03-16',263.73),
(78,78,2,'2026-03-19',318.25),
(79,79,3,'2026-03-21',188.33),
(80,80,4,'2026-03-26',164.96);


INSERT INTO Orden_comp VALUES
(1,1,'2024-01-08','2024-01-15',3740.00,'RECIBIDO'),
(2,2,'2024-01-15','2024-01-22',4083.50,'RECIBIDO'),
(3,3,'2024-01-22','2024-01-30',3210.20,'RECIBIDO'),
(4,4,'2024-02-05','2024-02-12',3625.00,'RECIBIDO'),
(5,5,'2024-02-12','2024-02-20',3829.00,'RECIBIDO'),

(6,6,'2024-02-20','2024-02-28',4490.50,'RECIBIDO'),
(7,7,'2024-03-05','2024-03-12',1890.00,'RECIBIDO'),
(8,8,'2024-03-12','2024-03-20',2750.00,'RECIBIDO'),
(9,9,'2024-03-20','2024-03-28',1320.00,'RECIBIDO'),
(10,10,'2024-04-02','2024-04-10',2980.00,'RECIBIDO'),

(11,11,'2024-04-08','2024-04-15',1560.00,'RECIBIDO'),
(12,12,'2024-04-15','2024-04-23',1840.00,'RECIBIDO'),
(13,13,'2024-04-25','2024-05-02',2200.00,'RECIBIDO'),
(14,14,'2024-05-05','2024-05-12',1780.00,'RECIBIDO'),
(15,15,'2024-05-15','2024-05-22',2540.00,'RECIBIDO'),

(16,16,'2024-05-25','2024-06-02',1890.00,'RECIBIDO'),
(17,17,'2024-06-05','2024-06-12',3200.00,'RECIBIDO'),
(18,18,'2024-06-12','2024-06-20',1450.00,'RECIBIDO'),
(19,19,'2024-06-20','2024-06-28',1680.00,'RECIBIDO'),
(20,20,'2024-07-01','2024-07-08',2250.00,'RECIBIDO'),

(21,21,'2024-07-08','2024-07-15',1980.00,'RECIBIDO'),
(22,22,'2024-07-15','2024-07-23',2400.00,'RECIBIDO'),
(23,23,'2024-07-25','2024-08-02',1350.00,'RECIBIDO'),
(24,24,'2024-08-05','2024-08-12',1750.00,'RECIBIDO'),
(25,25,'2024-08-15','2024-08-22',2100.00,'RECIBIDO'),

(26,26,'2024-08-25','2024-09-02',1890.00,'RECIBIDO'),
(27,27,'2024-09-05','2024-09-12',1650.00,'RECIBIDO'),
(28,28,'2024-09-15','2024-09-22',2400.00,'RECIBIDO'),
(29,29,'2024-09-25','2024-10-02',1320.00,'RECIBIDO'),
(30,30,'2024-10-05','2024-10-12',2850.00,'RECIBIDO'),

(31,31,'2024-10-15','2024-10-22',3100.00,'RECIBIDO'),
(32,32,'2024-10-25','2024-11-02',2650.00,'RECIBIDO'),
(33,33,'2024-11-05','2024-11-12',1780.00,'RECIBIDO'),
(34,34,'2024-11-15','2024-11-22',2200.00,'RECIBIDO'),
(35,35,'2024-11-25','2024-12-02',1450.00,'RECIBIDO'),

(36,36,'2024-12-05','2024-12-12',1980.00,'RECIBIDO'),
(37,37,'2024-12-15','2024-12-22',3200.00,'RECIBIDO'),
(38,38,'2024-12-22','2024-12-29',1750.00,'RECIBIDO'),
(39,39,'2025-01-05','2025-01-12',1680.00,'RECIBIDO'),
(40,40,'2025-01-15','2025-01-22',2400.00,'RECIBIDO'),

(41,41,'2025-01-25','2025-02-02',4200.00,'RECIBIDO'),
(42,42,'2025-02-05','2025-02-12',3800.00,'RECIBIDO'),
(43,43,'2025-02-15','2025-02-22',4600.00,'RECIBIDO'),
(44,44,'2025-02-25','2025-03-04',3500.00,'RECIBIDO'),
(45,45,'2025-03-05','2025-03-12',2100.00,'RECIBIDO'),

(46,46,'2025-03-15','2025-03-22',3900.00,'RECIBIDO'),
(47,47,'2025-03-25','2025-04-02',3700.00,'RECIBIDO'),
(48,48,'2025-04-05','2025-04-12',2500.00,'RECIBIDO'),
(49,49,'2025-04-15','2025-04-22',2300.00,'RECIBIDO'),
(50,50,'2025-04-25','2025-05-02',1850.00,'RECIBIDO'),

(51,51,'2025-05-05','2025-05-12',2100.00,'APROBADO'),
(52,52,'2025-05-15','2025-05-22',2750.00,'APROBADO'),
(53,53,'2025-05-25','2025-06-02',1450.00,'APROBADO'),
(54,54,'2025-06-05','2025-06-12',2350.00,'APROBADO'),
(55,55,'2025-06-15','2025-06-22',980.00,'APROBADO'),

(56,56,'2025-06-25','2025-07-02',2980.00,'APROBADO'),
(57,57,'2025-07-05','2025-07-12',1650.00,'APROBADO'),
(58,58,'2025-07-15','2025-07-22',1840.00,'APROBADO'),
(59,59,'2025-07-25','2025-08-02',1320.00,'APROBADO'),
(60,60,'2025-08-05','2025-08-12',1560.00,'APROBADO'),

(61,61,'2026-01-05','2026-01-12',2250.00,'SOLICITADO'),
(62,62,'2026-01-10','2026-01-17',1980.00,'SOLICITADO'),
(63,63,'2026-01-15','2026-01-22',1750.00,'SOLICITADO'),
(64,64,'2026-01-20','2026-01-27',1200.00,'SOLICITADO'),
(65,65,'2026-01-25','2026-02-01',4200.00,'SOLICITADO'),

(66,66,'2026-02-05','2026-02-12',3850.00,'SOLICITADO'),
(67,67,'2026-02-15','2026-02-22',3400.00,'SOLICITADO'),
(68,68,'2026-02-25','2026-03-04',2950.00,'SOLICITADO'),
(69,69,'2026-03-05','2026-03-12',3100.00,'SOLICITADO'),
(70,70,'2026-03-15','2026-03-22',2850.00,'SOLICITADO'),

(71,71,'2026-03-20','2026-03-27',1450.00,'SOLICITADO'),
(72,72,'2026-03-25','2026-04-01',3600.00,'SOLICITADO'),
(73,73,'2026-04-01','2026-04-08',1980.00,'SOLICITADO'),
(74,74,'2026-04-05','2026-04-12',1750.00,'SOLICITADO'),
(75,75,'2026-04-10','2026-04-17',1650.00,'SOLICITADO'),

(76,76,'2026-04-15','2026-04-22',1200.00,'CANCELADO'),
(77,77,'2026-04-20','2026-04-27',1850.00,'CANCELADO'),
(78,78,'2026-04-25','2026-05-02',2400.00,'CANCELADO'),
(79,79,'2026-05-01','2026-05-08',980.00,'CANCELADO'),
(80,80,'2026-05-05','2026-05-12',1500.00,'CANCELADO');


INSERT INTO Det_orden_comp VALUES
(1,1,1,3,50,1250.00),
(2,2,2,3,75,1850.00),
(3,3,3,3,40,980.00),
(4,4,4,3,80,2100.00),
(5,5,5,3,60,1650.00),
(81,1,2,3,20,450.00),
(82,1,3,3,15,375.00),
(83,1,4,3,25,625.00),
(84,1,5,3,10,320.00),
(85,1,6,3,30,720.00),

(6,6,6,3,90,2400.00),
(86,2,7,3,25,625.00),
(87,2,8,3,10,425.00),
(88,2,9,3,30,567.00),
(89,2,10,3,20,378.00),
(90,2,11,3,15,238.50),
(7,7,7,3,70,1890.00),
(91,3,12,3,20,358.20),
(92,3,13,3,15,373.50),
(93,3,14,3,25,572.50),
(94,3,15,3,10,149.00),
(95,3,16,3,30,777.00),
(8,8,8,3,100,2750.00),
(96,4,17,3,30,387.00),
(97,4,18,3,20,378.00),
(98,4,19,3,15,253.50),
(99,4,20,3,25,347.50),
(100,4,21,3,10,159.00),
(9,9,9,3,45,1320.00),
(101,5,22,3,20,398.00),
(102,5,23,3,15,262.50),
(103,5,24,3,25,372.50),
(104,5,25,3,10,249.00),
(105,5,26,3,30,897.00),
(10,10,10,3,110,2980.00),
(106,6,27,3,20,438.00),
(107,6,28,3,15,403.50),
(108,6,29,3,25,873.00),
(109,6,30,3,10,199.00),
(110,6,31,3,30,177.00),

(11,11,11,3,55,1560.00),
(12,12,12,3,65,1840.00),
(13,13,13,3,80,2200.00),
(14,14,14,3,60,1780.00),
(15,15,15,3,95,2540.00),

(16,16,16,3,70,1890.00),
(17,17,17,3,120,3200.00),
(18,18,18,3,50,1450.00),
(19,19,19,3,60,1680.00),
(20,20,20,3,85,2250.00),

(21,21,21,3,75,1980.00),
(22,22,22,3,90,2400.00),
(23,23,23,3,50,1350.00),
(24,24,24,3,65,1750.00),
(25,25,25,3,80,2100.00),

(26,26,26,3,70,1890.00),
(27,27,27,3,60,1650.00),
(28,28,28,3,90,2400.00),
(29,29,29,3,45,1320.00),
(30,30,30,3,105,2850.00),

(31,31,31,3,120,3100.00),
(32,32,32,3,95,2650.00),
(33,33,33,3,65,1780.00),
(34,34,34,3,80,2200.00),
(35,35,35,3,50,1450.00),

(36,36,36,3,75,1980.00),
(37,37,37,3,120,3200.00),
(38,38,38,3,65,1750.00),
(39,39,39,3,60,1680.00),
(40,40,40,3,90,2400.00),

(41,41,41,3,150,4200.00),
(42,42,42,3,135,3800.00),
(43,43,43,3,160,4600.00),
(44,44,44,3,125,3500.00),
(45,45,45,3,70,2100.00),

(46,46,46,3,140,3900.00),
(47,47,47,3,130,3700.00),
(48,48,48,3,90,2500.00),
(49,49,49,3,85,2300.00),
(50,50,50,3,65,1850.00),

(51,51,51,2,80,2100.00),
(52,52,52,2,100,2750.00),
(53,53,53,2,50,1450.00),
(54,54,54,2,85,2350.00),
(55,55,55,2,35,980.00),

(56,56,56,2,110,2980.00),
(57,57,57,2,60,1650.00),
(58,58,58,2,65,1840.00),
(59,59,59,2,45,1320.00),
(60,60,60,2,55,1560.00),

(61,61,61,1,85,2250.00),
(62,62,62,1,75,1980.00),
(63,63,63,1,65,1750.00),
(64,64,64,1,40,1200.00),
(65,65,65,1,150,4200.00),

(66,66,66,1,135,3850.00),
(67,67,67,1,120,3400.00),
(68,68,68,1,105,2950.00),
(69,69,69,1,110,3100.00),
(70,70,70,1,100,2850.00),

(71,71,71,1,50,1450.00),
(72,72,72,1,130,3600.00),
(73,73,73,1,75,1980.00),
(74,74,74,1,65,1750.00),
(75,75,75,1,60,1650.00),

(76,76,76,4,40,1200.00),
(77,77,77,4,65,1850.00),
(78,78,78,4,85,2400.00),
(79,79,79,4,35,980.00),
(80,80,80,4,55,1500.00);



-- ============================================================================
-- ANEXO 1: CONSULTAS SQL (ALINEADAS AL INFORME WORD)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. CATÁLOGOS Y PRODUCTOS
-- ----------------------------------------------------------------------------

-- Consulta 1. Listado general de productos con precio unitario y estado
SELECT Nombre, Precio_uni, Estado
FROM Producto;

-- Consulta 2. Órdenes de compra registradas
SELECT Id_orden, Fecha_emi, Fecha_ent, Total, Estado_orden
FROM Orden_comp;

-- ----------------------------------------------------------------------------
-- 2. CONSULTAS CON INNER JOIN
-- ----------------------------------------------------------------------------

-- Consulta 3. Pedidos con razón social del cliente y fecha
SELECT
    p.Id_ped,
    c.razon_cli,
    p.Fecha_ped,
    p.Estado
FROM Pedido p
INNER JOIN CLIENTE c ON p.id_cliente = c.id_cliente;

-- Consulta 4. Productos con categoría y técnica de personalización
SELECT
    pr.Id_prod,
    pr.Nombre AS Producto,
    cat.Nombre AS Categoria,
    tp.Nombre AS Tecnica,
    pr.Precio_uni
FROM Producto pr
INNER JOIN Categoria cat ON pr.Id_cat = cat.Id_cat
INNER JOIN Tecnica_perz tp ON pr.Id_tecnica = tp.Id_tecnica;

-- Consulta adicional INNER JOIN: Despachos con cliente y distrito de entrega
SELECT
    d.Id_desp,
    p.Id_ped,
    c.razon_cli,
    dist.Nombre AS Distrito,
    d.Estado_despacho
FROM Despacho d
INNER JOIN Pedido p ON d.Id_ped = p.Id_ped
INNER JOIN CLIENTE c ON p.id_cliente = c.id_cliente
INNER JOIN Distrito dist ON d.Id_dist = dist.Id_dist;

-- Consulta adicional INNER JOIN: Comprobantes con pago y método de pago
SELECT
    comp.Id_comprob,
    comp.Tipo_comprob,
    comp.Monto_total,
    tp.Nombre AS Tipo_Pago,
    pg.Fecha_pago
FROM Comprobante comp
INNER JOIN Pago pg ON comp.Id_comprob = pg.Id_comprob
INNER JOIN Tipo_pago tp ON pg.Id_tipo_pag = tp.Id_tipo_pag;

-- Consulta adicional INNER JOIN: Órdenes de compra con proveedor y productos
SELECT
    oc.Id_orden,
    prov.Razon AS Proveedor,
    pr.Nombre AS Producto,
    doc.Cantidad,
    doc.Subtotal
FROM Orden_comp oc
INNER JOIN Proveedor prov ON oc.Id_prov = prov.Id_prov
INNER JOIN Det_orden_comp doc ON oc.Id_orden = doc.Id_orden
INNER JOIN Producto pr ON doc.Id_prod = pr.Id_prod;

-- ----------------------------------------------------------------------------
-- 3. CONSULTAS CON GROUP BY
-- ----------------------------------------------------------------------------

-- Consulta 5. Total de pedidos por cliente
SELECT
    c.razon_cli,
    COUNT(p.Id_ped) AS Total_Pedidos
FROM CLIENTE c
INNER JOIN Pedido p ON c.id_cliente = p.id_cliente
GROUP BY c.razon_cli;

-- Consulta 6. Cantidad de órdenes de compra por estado
SELECT
    Estado_orden,
    COUNT(*) AS Cantidad
FROM Orden_comp
GROUP BY Estado_orden;

-- ----------------------------------------------------------------------------
-- 4. CONSULTAS CON HAVING
-- ----------------------------------------------------------------------------

-- Consulta 7. Productos con más de 10 unidades vendidas
SELECT
    pr.Nombre,
    SUM(dp.Cantidad) AS Total_Vendido
FROM Producto pr
INNER JOIN Det_pedido dp ON pr.Id_prod = dp.Id_prod
GROUP BY pr.Nombre
HAVING SUM(dp.Cantidad) > 10;

-- Consulta adicional HAVING: Clientes con más de 3 pedidos registrados
SELECT
    c.razon_cli,
    COUNT(p.Id_ped) AS Total_Pedidos
FROM CLIENTE c
INNER JOIN Pedido p ON c.id_cliente = p.id_cliente
GROUP BY c.razon_cli
HAVING COUNT(p.Id_ped) > 3;

-- ----------------------------------------------------------------------------
-- 5. PARTICIONAMIENTO EN MYSQL WORKBENCH (RANGE BY YEAR)
-- ----------------------------------------------------------------------------
-- Nota: En MySQL, la columna de partición debe formar parte de la PRIMARY KEY.

-- Consulta 8. Creación, carga de datos y consulta de una partición específica
CREATE TABLE Pedido_Particionado (
    Id_ped INT NOT NULL,
    id_cliente INT NOT NULL,
    Fecha_ped DATE NOT NULL,
    Estado VARCHAR(30) NOT NULL,
    PRIMARY KEY (Id_ped, Fecha_ped)
)
PARTITION BY RANGE (YEAR(Fecha_ped)) (
    PARTITION p_2024 VALUES LESS THAN (2025),
    PARTITION p_2025 VALUES LESS THAN (2026),
    PARTITION p_2026 VALUES LESS THAN (2027),
    PARTITION p_futuro VALUES LESS THAN MAXVALUE
);

INSERT INTO Pedido_Particionado (Id_ped, id_cliente, Fecha_ped, Estado)
SELECT Id_ped, id_cliente, Fecha_ped, Estado
FROM Pedido;

SELECT *
FROM Pedido_Particionado PARTITION (p_2025);

-- Verificación de distribución de filas por partición
SELECT PARTITION_NAME, TABLE_ROWS
FROM INFORMATION_SCHEMA.PARTITIONS
WHERE TABLE_SCHEMA = 'SumakVillaDB'
  AND TABLE_NAME = 'Pedido_Particionado';

-- ----------------------------------------------------------------------------
-- 6. TRIGGER EN MYSQL WORKBENCH (AUDITORÍA DE NUEVOS PEDIDOS)
-- ----------------------------------------------------------------------------

-- Consulta 9. Tabla de registro, creación del trigger, carga de prueba y consulta
CREATE TABLE Log_Pedido (
    Id_log INT AUTO_INCREMENT PRIMARY KEY,
    Id_ped INT NOT NULL,
    Estado_nuevo VARCHAR(30) NOT NULL,
    Fecha_registro DATETIME NOT NULL
);

DELIMITER //

CREATE TRIGGER trg_log_nuevo_pedido
AFTER INSERT ON Pedido
FOR EACH ROW
BEGIN
    INSERT INTO Log_Pedido (Id_ped, Estado_nuevo, Fecha_registro)
    VALUES (NEW.Id_ped, NEW.Estado, NOW());
END //

DELIMITER ;

-- 10 registros nuevos en Pedido para activar el trigger automáticamente
INSERT INTO Pedido (Id_ped, id_cliente, Id_estado, Fecha_ped, Fecha_ent, Estado, Obs) VALUES
(101, 1, 1, '2026-06-01', '2026-06-10', 'PENDIENTE', 'Pedido de polos corporativos personalizados'),
(102, 2, 2, '2026-06-03', '2026-06-12', 'ADMITIDO', 'Pedido de gorras bordadas para campaña'),
(103, 3, 3, '2026-06-05', '2026-06-15', 'PROCESADO', 'Pedido de tazas sublimadas institucionales'),
(104, 4, 4, '2026-06-07', '2026-06-16', 'ENTREGADO', 'Pedido de tomatodos promocionales entregados'),
(105, 5, 1, '2026-06-10', '2026-06-20', 'PENDIENTE', 'Pedido de agendas ejecutivas con logotipo'),
(106, 6, 2, '2026-06-12', '2026-06-22', 'ADMITIDO', 'Pedido de memorias USB corporativas'),
(107, 7, 3, '2026-06-15', '2026-06-25', 'PROCESADO', 'Pedido de mochilas publicitarias en producción'),
(108, 8, 4, '2026-06-18', '2026-06-28', 'ENTREGADO', 'Pedido de bolsas ecológicas entregadas'),
(109, 9, 1, '2026-06-20', '2026-06-30', 'PENDIENTE', 'Pedido de lapiceros personalizados para evento'),
(110, 10, 2, '2026-06-22', '2026-07-02', 'ADMITIDO', 'Pedido de llaveros corporativos admitido');

-- Consultar los registros generados automáticamente por el trigger
SELECT Id_log, Id_ped, Estado_nuevo, Fecha_registro
FROM Log_Pedido;

-- Consultar los pedidos del log junto con la razón social del cliente
SELECT
    lp.Id_ped,
    c.razon_cli,
    lp.Estado_nuevo,
    lp.Fecha_registro
FROM Log_Pedido lp
INNER JOIN Pedido p ON lp.Id_ped = p.Id_ped
INNER JOIN CLIENTE c ON p.id_cliente = c.id_cliente;
