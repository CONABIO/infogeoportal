select count(1)
from snib.informaciongeoportal_siya
where obsusoinfo like "%coordenada obscurecida%" or obsusoinfo like "%generalizada%"

/*agregar un campo de tipo booleano donde se marquen las coordenadas obscurecidas.*/

-- agregado 2025-05-23 prueba git


DELIMITER $$
-- Revisar que la _TTN_snib estae completa.
DROP PROCEDURE IF EXISTS `geoportal_trabajo`.`02_generatablaInformacionGeoportal` $$
CREATE DEFINER=`si`@`%` PROCEDURE `02_generatablaInformacionGeoportal`()
BEGIN
-- Después de la corrida del 2021 verificar en la tabla siyahistorico como se meteran los campos: vegetacionserenanalcms y regionmarinamapa

DROP TABLE IF EXISTS geoportal_trabajo.EjemplaresNoDebenAparecerGeoportal1;
DROP TABLE IF EXISTS geoportal_trabajo.EjemplaresNoDebenAparecerGeoportal;
DROP TABLE IF EXISTS geoportal_trabajo.EjemplarColeccion;
DROP TABLE IF EXISTS geoportal_trabajo.EjemplarColeccionNomComun;
DROP TABLE IF EXISTS geoportal_trabajo.EjemplarVegetacionINEGI;
DROP TABLE IF EXISTS geoportal_trabajo.InformacionGeoportal;
DROP TABLE IF EXISTS geoportal_trabajo.nombrecomun;
DROP TABLE IF EXISTS geoportal_trabajo.ejemplaresnovalpaisvalambientemarino;
DROP TABLE IF EXISTS geoportal_trabajo.InformacionGeoportal_siya;
DROP TABLE IF EXISTS geoportal_trabajo.ejemplariucn_nom;

-- Mandamos a ejecutar el procedimiento 01_preparanombrecomun

CALL geoportal_trabajo.01_preparanombrecomun();
Call geoportal_trabajo.01_creaAreasNaturales();

-- estas tablas las generamos para que sea más rápido el proceso

DROP TABLE IF EXISTS geoportal_trabajo.nombre1;

create table geoportal_trabajo.nombre1
select llavenombre,grupo,subgrupo,reinocat,divisionphylumcat,clasecat,autoranioordencat,ordencat,subordencat,autoraniofamiliacat,familiacat,estatusfamiliacat,subfamiliacat,estatussubfamiliacat,tribucat,estatustribucat,generocat,
estatusgenerocat,autoraniogenerocat,subgenerocat,autoraniosubgenerocat,estatussubgenerocat,epitetoespecificocat,estatusespeciecat,autoranioespeciecat,categoriainfraespeciecat,epitetoinfraespecificocat,estatusinfraespeciecat,
autoranioinfraespeciecat,categoriainfraespecie2cat,epitetoinfraespecifico2cat,catdiccinfraespecie2cat,estatusinfraespecie2cat,autoranioinfraespecie2cat,idnombrecat,cattaxcat,catalogocat,comentarioscat,fuentecat,reinooriginal,
divisionphylumoriginal,claseoriginal,ordenoriginal,autoranioordenoriginal,subordenoriginal,familiaoriginal,autoraniofamiliaoriginal,subfamiliaoriginal,tribuoriginal,generooriginal,autoraniogenerooriginal,estatusgenerooriginal,
subgenerooriginal,epitetoespecificooriginal,autoranioespecieoriginal,estatusespecieoriginal,categoriainfraespecieoriginal,epitetoinfraespecificooriginal,autoranioinfraespecieoriginal,estatusinfraespecieoriginal,
categoriainfraespecieoriginal2,epitetoinfraespecificooriginal2,autoranioinfraespecieoriginal2,estatusinfraespecieoriginal2,idnombrebdmigrada,proyecto,clavebasedatos,identificacionarchivo,rutabd,difvalidaciontax,
distribucionnom2010,taxonextinto,reinocatvalido,sistemaclasificacionreinocatvalido,divisionphylumcatvalido,sistemaclasificaciondivisionphylumcatvalido,clasecatvalido,sistemaclasificacionclasecatvalido,autoranioordencatvalido,
ordencatvalido,sistemaclasificacionordencatvalido,subordencatvalido,sistemaclasificacionsubordencatvalido,autoraniofamiliacatvalido,familiacatvalido,sistemaclasificacionfamiliacatvalido,
estatusfamiliacatvalido,subfamiliacatvalido,sistemaclasificacionsubfamiliacatvalido,Estatussubfamiliacatvalido,tribucatvalido,sistemaclasificaciontribucatvalido,estatustribucatvalido,generocatvalido,sistemaclasificaciongenerocatvalido,estatusgenerocatvalido,autoraniogenerocatvalido,subgenerocatvalido,
sistemaclasificacionsubgenerocatvalido,autoraniosubgenerocatvalido,estatussubgenerocatvalido,epitetoespecificocatvalido,catdiccespeciecatvalido,estatusespeciecatvalido,autoranioespeciecatvalido,categoriainfraespeciecatvalido,
epitetoinfraespecificocatvalido,catdiccinfraespeciecatvalido,estatusinfraespeciecatvalido,autoranioinfraespeciecatvalido,categoriainfraespecie2catvalido,epitetoinfraespecifico2catvalido,catdiccinfraespecie2catvalido,
estatusinfraespecie2catvalido,autoranioinfraespecie2catvalido,idnombrecatvalido,cattaxcatvalido,catalogocatvalido,comentarioscatvalido,fuentecatvalido,homonimosgenero,homonimosespecie,homonimosinfraespecie,
homonimosgenerocatvalido,homonimosespeciecatvalido,homonimosinfraespeciecatvalido,ambientenombre,origenambientenombre,formadecrecimiento,gruposcat,hibrido,categoriaoriginalscat,nombreoriginallimpioscat,
categoriacatscat,nombrecatscat,estatuscatscat,autoridadcatscat,categoriavalidocatscat,nombrevalidocatscat,estatusvalidocatscat,autoridadvalidocatscat,ultimafechaactualizacion,fechaactualizacion,version,estadoregistro,
anotaciontaxonoriginal from snib.nombre;




alter table geoportal_trabajo.nombre1 add primary key(llavenombre),add index uno(idnombrecat);


/* Primero obtenemos los ejemplares que no deben aparecer excluimos de esta selección los ejemplares cuya distancia es <=20 Km, despues cruzamos esta tabla 
vs todos los ejemplares y dejamos los ejemplares que no aparecen en la tabla anterior. */


/* Filtro para excluir los ejemplares no validos por ambiente, sin marca en el campo probablelocnodecampo y que no provengan del proyecto AverAves*/
create table geoportal_trabajo.EjemplaresNoDebenAparecerGeoportal1
select e.llaveejemplar,e.validacionambientegeneral,r.estadocodigovalidacion 
from snib.ejemplar_curatorial e inner join snib.proyecto p on e.llaveproyecto=p.llaveproyecto
inner join snib.conabiogeografia r on e.llaveregionsitiosig=r.llaveregionsitiosig
where e.validacionambientegeneral = "NO VALIDO" and e.probablelocnodecampo='' and p.proyecto<>'AverAves';

/*Filtro para excluir ejemplares no validos a pais o no validos a estado o no validos a municio pero cuya distancia del centro del municipio es mayor a 20 Km, revisar localidadcodigovalidacion<>20 que significa */
insert into geoportal_trabajo.EjemplaresNoDebenAparecerGeoportal1
select e.llaveejemplar,e.validacionambientegeneral,r.estadocodigovalidacion 
from snib.ejemplar_curatorial e inner join snib.conabiogeografia r on e.llaveregionsitiosig=r.llaveregionsitiosig
where r.localidadcodigovalidacion<>20 and
(r.paiscodigovalidacion = 0 or
r.estadocodigovalidacion = 0 or
(r.municipiocodigovalidacion = 0 and r.distmpio>20000));


/* Filtro para excluir los no validos por localidad que se ubican en zona costera o continental */
insert into geoportal_trabajo.EjemplaresNoDebenAparecerGeoportal1
select e.llaveejemplar,e.validacionambientegeneral,r.estadocodigovalidacion
from snib.ejemplar_curatorial e inner join snib.conabiogeografia r on e.llaveregionsitiosig=r.llaveregionsitiosig
inner join snib.zonamapa z on r.idzonamapa=z.idzonamapa
where (r.localidadcodigovalidacion = 0 and (z.zonamapa rlike "COSTER[AO]$" or z.zonamapa like "%CONTINENTAL" or z.zonamapa like "%COSTERA CONTINENTAL 2 KM"));

/*Como algunos ejemplares caén en más de un filtro, agrupamos las llaveejemplar para tener registros únicos*/
create table geoportal_trabajo.EjemplaresNoDebenAparecerGeoportal
select distinct * from geoportal_trabajo.EjemplaresNoDebenAparecerGeoportal1;

/* Agregamos índice a la tabla antes creada */
ALTER TABLE `geoportal_trabajo`.`EjemplaresNoDebenAparecerGeoportal` ADD INDEX `Index_1`(`llaveejemplar`);

/* Generamos la tabla de los ejemplares no validos a país (país <> MÉXICO, pero validos por ambiente Marino */
create table geoportal_trabajo.ejemplaresnovalpaisvalambientemarino
SELECT e.llaveejemplar
FROM geoportal_trabajo.EjemplaresNoDebenAparecerGeoportal eng inner join snib.ejemplar_curatorial e on eng.llaveejemplar=e.llaveejemplar
inner join snib.nombre_taxonomia n on e.llavenombre=n.llavenombre inner join snib.conabiogeografia r on e.llaveregionsitiosig=r.llaveregionsitiosig
inner join snib.procesovalidacion p on r.idprocesovalidacion=p.idprocesovalidacion
where n.ambientenombre='Marino'
and p.procesovalidacion in ('W_no valido2012','W_no valido2018','W_no valido2020')
and e.validacionambientegeneral='VALIDO';

ALTER TABLE `geoportal_trabajo`.`ejemplaresnovalpaisvalambientemarino` ADD INDEX `Index_1`(`llaveejemplar`);

/*Eliminamos de los ejemplares a no publicar en el geoportal aquellos que sean validos por ambiente Marino y no validos a País. 

NOTA: el delete NO TIENE WHERE por que elimina apartir de una tabla creada con los elementos a eliminar
  */
DELETE geoportal_trabajo.EjemplaresNoDebenAparecerGeoportal 
FROM geoportal_trabajo.EjemplaresNoDebenAparecerGeoportal 
INNER JOIN geoportal_trabajo.ejemplaresnovalpaisvalambientemarino on geoportal_trabajo.EjemplaresNoDebenAparecerGeoportal.llaveejemplar=geoportal_trabajo.ejemplaresnovalpaisvalambientemarino.llaveejemplar;


/* El proceso para obtener todos los ejemplares se tuvo que hacer en pasos, porque el qry era muy complejo y tardaba más de 4 días en dar resultados */

/* Creamos la tabla EjemplarColeccion .*/
create table geoportal_trabajo.EjemplarColeccion
select e.llaveejemplar,e.llavenombre,
concat(cci.siglascoleccion,' ',cci.nombrecoleccion) AS coleccion,
concat(ci.siglasinstitucion,' ',ci.nombreinstitucion) AS institucion,
cci.paiscoleccion
from snib.ejemplar_curatorial e inner join snib.catcoleccion cci on e.idcoleccioncat=cci.idcoleccioncat
inner join snib.catinstitucion ci on e.idinstitucioncat=ci.idinstitucioncat
where estadoregistro='';

/* Agregamos índice a la tabla antes creada EjemplarColeccion*/
ALTER TABLE `geoportal_trabajo`.`EjemplarColeccion` ADD COLUMN iucn varchar(1024) NOT NULL, ADD COLUMN nom059 varchar(512) NOT NULL, ADD COLUMN cites varchar(512) NOT NULL,
ADD COLUMN categoriaresidenciaaves varchar(100) NOT NULL DEFAULT '',
ADD COLUMN prioritaria varchar(100) NOT NULL  DEFAULT '',
ADD COLUMN nivelprioridad enum('','Alta','Media','Menor') NOT NULL  DEFAULT '',
ADD COLUMN exoticainvasora varchar(50) NOT NULL  DEFAULT '',
ADD COLUMN endemismo enum('','Cuasiendémica','Endémica','Semiendémica') NOT NULL  DEFAULT '',
ADD INDEX `Index_1`(`llaveejemplar`),ADD INDEX `Index_2`(`llavenombre`);


UPDATE geoportal_trabajo.EjemplarColeccion e INNER JOIN snib.ejemplarcategoriariesgo ecr on e.llaveejemplar=ecr.llaveejemplar
inner join snib.categoriasproteccion c on ecr.idcategoriaresidenciaaves=c.idcategoriaproteccion
set categoriaresidenciaaves=c.categoria
where c.lista='residenciaaves';

UPDATE geoportal_trabajo.EjemplarColeccion e INNER JOIN snib.ejemplarcategoriariesgo ecr on e.llaveejemplar=ecr.llaveejemplar
inner join snib.categoriasproteccion c on ecr.idprioritarias=c.idcategoriaproteccion
set e.prioritaria=c.categoria,
e.nivelprioridad=ecr.nivelprioridad
where c.lista='prioritarias';

UPDATE geoportal_trabajo.EjemplarColeccion e INNER JOIN snib.ejemplarcategoriariesgo ecr on e.llaveejemplar=ecr.llaveejemplar
inner join snib.categoriasproteccion c on ecr.idestatusinvasora=c.idcategoriaproteccion
set exoticainvasora=c.categoria
where c.lista='estatusinvasora';

UPDATE geoportal_trabajo.EjemplarColeccion e INNER JOIN snib.ejemplarcategoriariesgo ecr on e.llaveejemplar=ecr.llaveejemplar
inner join snib.categoriasproteccion c on ecr.idendemismo=c.idcategoriaproteccion
set endemismo=c.categoria
where c.lista='endemismo';

UPDATE geoportal_trabajo.EjemplarColeccion e INNER JOIN snib.ejemplarIUCN i on e.llaveejemplar=i.llaveejemplar
set e.iucn=i.IUCN;

UPDATE geoportal_trabajo.EjemplarColeccion e INNER JOIN snib.ejemplarNOM i on e.llaveejemplar=i.llaveejemplar
set e.nom059=i.NOM;

UPDATE geoportal_trabajo.EjemplarColeccion e INNER JOIN snib.ejemplarCITES i on e.llaveejemplar=i.llaveejemplar
set e.cites=i.CITES;
 
/* Creamos la estructura de la tabla nombrecomun*/
CREATE TABLE `geoportal_trabajo`.`nombrecomun` (
  `llavenombre` VARCHAR(32) NOT NULL,
  `nombrecomunCatalogo` TEXT NOT NULL,
  `nombrecomunOriginal` TEXT NOT NULL,
  `nombrecomun` TEXT NOT NULL,
   PRIMARY KEY(`llavenombre`)
) ENGINE = Aria
CHARACTER SET utf8 COLLATE utf8_general_ci;

/*En la tabla antes creada agregamos la lista de nombres de la tabla nombre*/
INSERT INTO geoportal_trabajo.nombrecomun(llavenombre,nombrecomunCatalogo,nombrecomunOriginal,nombrecomun)
select n.llavenombre,'','','' from snib.nombre_taxonomia n where estadoregistro='';

/* Se llena el campo nombrecomunCatalogo obteniendo el valor de una tabla creada en el procedimiento 01_preparanombrecomun()*/
UPDATE geoportal_trabajo.nombrecomun nc inner join geoportal_trabajo.nombrecomunCatalogoEspañol ncce on nc.llavenombre=ncce.llavenombre
SET nc.nombrecomunCatalogo=ncce.nombrecomun;

/* Se llena el campo nombrecomunOriginal obteniendo el valor de una tabla creada en el procedimiento 01_preparanombrecomun()*/
UPDATE geoportal_trabajo.nombrecomun nc inner join geoportal_trabajo.nombrecomunOriginalEspañol ncoe on nc.llavenombre=ncoe.llavenombre
SET nc.nombrecomunOriginal=ncoe.nombrecomun;

/*Se llena el campo nombrecomun dando prioridad al nombrecomun asignado por el area de scat, si no existe nombrecomun asignado por el area de scat se deja el nombrecomun de la fuente original*/
UPDATE geoportal_trabajo.nombrecomun
set nombrecomun=if(nombrecomunCatalogo<>'',nombrecomunCatalogo,nombrecomunOriginal);

/* Creamos la tabla EjemplarColeccionNomComun*/
create table geoportal_trabajo.EjemplarColeccionNomComun
select ec.llaveejemplar,ec.coleccion,ec.institucion,ec.paiscoleccion,nc.nombrecomun,ec.cites,ec.iucn,ec.nom059,categoriaresidenciaaves,prioritaria,nivelprioridad,exoticainvasora,endemismo
from geoportal_trabajo.EjemplarColeccion ec inner join geoportal_trabajo.nombrecomun nc on ec.llavenombre = nc.llavenombre;

ALTER TABLE geoportal_trabajo.EjemplarColeccionNomComun add index uno(llaveejemplar);

/* Creamos la tabla EjemplarVegetacionINEGI , para armar el campo usvINEGI se toma el ultimo codigo válido, en este caso es el de serie VII*/
create table geoportal_trabajo.EjemplarVegetacionINEGI
SELECT e.llaveejemplar, si.despveg AS usvserieI, sii.despveg AS usvserieII, siii.despveg AS usvserieIII, siv.despveg AS usvserieIV,sINEGI.despecov as usvINEGI
FROM snib.ejemplar_curatorial e inner join snib.conabiogeografia r on e.llaveregionsitiosig=r.llaveregionsitiosig
LEFT JOIN snib.usv_INEGI as si ON r.usvsIcodigo = si.usvsnum 
LEFT JOIN snib.usv_INEGI AS sii ON r.usvsIIcodigo = sii.usvsnum 
LEFT JOIN snib.usv_INEGI AS siii ON r.usvsIIIcodigo = siii.usvsnum
LEFT JOIN snib.usv_INEGI AS siv ON r.usvsIVcodigo = siv.usvsnum
LEFT JOIN snib.usv_INEGI AS sINEGI ON r.usvsVIIcodigo = sINEGI.usvsnum
where estadoregistro='';


/* Adicionar indice en el campo llaveejemplar en la tabla EjemplarVegetacionINEGI, */
ALTER TABLE `geoportal_trabajo`.`EjemplarVegetacionINEGI` ADD INDEX `Index_1`(`llaveejemplar`),
MODIFY COLUMN `usvserieI` VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci,
MODIFY COLUMN `usvserieII` VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci,
MODIFY COLUMN `usvserieIII` VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci,
MODIFY COLUMN `usvserieIV` VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci,
MODIFY COLUMN `usvINEGI` VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci;


/* Actualizamos los valores NO EMPATA a null */
update geoportal_trabajo.EjemplarVegetacionINEGI
set usvserieI = case when usvserieI = "NO EMPATA" or usvserieI is null then '' else usvserieI end,
usvserieII = case when usvserieII = "NO EMPATA" or usvserieII is null then '' else usvserieII end,
usvserieIII = case when usvserieIII = "NO EMPATA" or usvserieIII is null then '' else usvserieIII end,
usvserieIV = case when usvserieIV = "NO EMPATA" or usvserieIV is null then '' else usvserieIV end,
usvINEGI = case when usvINEGI = "NO EMPATA" or usvINEGI is null then '' else usvINEGI end;

/* Se crea la tabla InformacionGeoportal */
create table geoportal_trabajo.InformacionGeoportal
character set = utf8 COLLATE utf8_general_ci select e.llaveejemplar,
ro.paisoriginal,
ro.estadooriginal,
ro.municipiooriginal,
l.localidad,
rm.clavepaismapa,
rm.nombrepaismapa as paismapa,
-- rm.claveestadomapa,
rm.nombreestadomapa as estadomapa,
z.zonamapa,
r.longitudconabio as longitud,
-- e.proyecto,
-- e.clavebasedatos,
-- e.identificacionarchivo,
-- e.fuenteoriginal,
re.tiporestriccion,
e.cuarentena,
e.observacionusoinformacion as obsusoinfo,
n.reinocat as reino,
n.divisionphylumcat as phylumdivision,
n.clasecat as clase,
n.ordencat as orden,
case when n.familiacat<>'' then n.familiacat when nol.familiaoriginallimpio not in ('NO DISPONIBLE','',"indet","indet.","auxiliar2","ns","ns1","undet.","unidentified","unknown") then nol.familiaoriginallimpio else '' end as familia,
case when n.generocat<>'' then n.generocat when nol.generooriginallimpio not in ('NO DISPONIBLE','',"indet","indet.","auxiliar2","ns","ns1","undet.","unidentified","unknown") then nol.generooriginallimpio else '' end as genero,

if(n.comentarioscat like '%Validado completamente%',n.nombrecatscat,if(n.comentarioscat like '%Falta validar taxón%',n.nombreoriginallimpioscat,'')) as especie,

case when n.generocatvalido not in ('NO DISPONIBLE','') and n.epitetoespecificocatvalido not in ('NO DISPONIBLE','') then
trim(concat(n.generocatvalido,
case when n.subgenerocatvalido not in ('NO DISPONIBLE','') then concat(" (",n.subgenerocatvalido,")") else "" end,
case when n.epitetoinfraespecificocatvalido not in ('NO DISPONIBLE','') then concat(' ',
case when n.epitetoespecificocatvalido in ('NO DISPONIBLE','') then '' else n.epitetoespecificocatvalido end,' ',
case when n.epitetoinfraespecificocatvalido in ('NO DISPONIBLE','') then '' else n.epitetoinfraespecificocatvalido end,' ',n.epitetoinfraespecifico2catvalido)
else concat(' ', case when n.epitetoespecificocatvalido in ('NO DISPONIBLE','') then '' else n.epitetoespecificocatvalido end)end))
else '' end as especievalida,
case when n.generocatvalido not in ('NO DISPONIBLE','') and n.epitetoespecificocatvalido not in ('NO DISPONIBLE','') then
trim(concat(n.generocatvalido," ",n.epitetoespecificocatvalido)) else "" end as especievalidabusqueda,
n.taxonextinto,
if(e.procedenciadatos='FossilSpecimen','SI','') as ejemplarfosil
from  snib.ejemplar_curatorial e inner join snib.proyecto p on e.llaveproyecto=p.llaveproyecto
inner join snib.localidad l on e.idlocalidad=l.idlocalidad
inner join snib.conabiogeografia r on e.llaveregionsitiosig = r.llaveregionsitiosig
inner join snib.regionmapa rm on r.idregionmapa=rm.idregionmapa
inner join snib.zonamapa z on r.idzonamapa=z.idzonamapa
inner join snib.geografiaoriginal go on e.llavesitio=go.llavesitio
inner join snib.regionoriginal ro on go.idregionoriginal=ro.idregionoriginal
inner join geoportal_trabajo.nombre1 n on e.llavenombre = n.llavenombre
inner join snib.nombreoriginallimpio nol on e.llavenombre=nol.llavenombre
inner join snib.restriccionejemplar re on e.idrestriccionejemplar = re.idrestriccionejemplar
where e.estadoregistro='' and r.longitudconabio is not null;


/*Agregamos indices a la tabla InformacionGeoportal*/
ALTER TABLE `geoportal_trabajo`.`InformacionGeoportal` ADD COLUMN `eliminar` CHAR(2),
 ADD INDEX `Index_1`(`llaveejemplar`),
 ADD INDEX `Index_2`(`paisoriginal`),
 ADD INDEX `Index_3`(`tiporestriccion`),
 ADD INDEX `Index_4`(`cuarentena`),
 ADD INDEX `Index_5`(`eliminar`),
 ADD INDEX `Index_6`(`estadooriginal`),
 ADD INDEX `Index_7`(`paisoriginal`,`eliminar`),
 ADD INDEX `Index_8`(`paismapa`,`eliminar`),
 ADD INDEX `Index_9`(`obsusoinfo`),
 ADD INDEX `Index_10`(`paismapa`,`estadomapa`),
 ADD INDEX `Index_11`(`familia`),
 ADD INDEX `Index_12`(`genero`),
 ADD INDEX `Index_13`(`especie`),
 ADD INDEX `Index_14`(`especievalida`),
 ADD INDEX `Index_15`(`reino`),
 ADD INDEX `Index_16`(`phylumdivision`),
 ADD INDEX `Index_17`(`clase`),
 ADD INDEX `Index_18`(`orden`),
 ADD INDEX `Index_19`(`estadomapa`),
 ADD INDEX `Index_20`(`municipiooriginal`),
 ADD INDEX `Index_21`(`paismapa`),
 ADD INDEX `Index_22`(`estadooriginal`),
 ADD INDEX `Index_23`(`localidad`),
 ADD INDEX `Index_24`(`taxonextinto`),
 ADD INDEX `Index_25`(`ejemplarfosil`);
 
/*Eliminamos los registros donde en los campos reino,phylumdivision,clase y orden haya un nulo, Esto tomando en cuenta que Diana Reviso aquellos registros donde venia información original y
valido que no se deberia publicar. , no quitar los fosiles o extintos*/

/*Reunión SNIB 11/06/2024 este filtro lo revisaran la SI, SIB y SCAT antes de aplicarse */
delete from geoportal_trabajo.InformacionGeoportal
where reino='' and phylumdivision='' and clase='' and orden='' and ejemplarfosil<>'SI' and taxonextinto<>'SI';

/*Marcamos los registros a conservar por caer dentro de mexico*/
update geoportal_trabajo.InformacionGeoportal
set eliminar = "NO"
where paisoriginal in ('','NO DISPONIBLE','032','AMERICA','EASTERN PACIFIC','GOLFE DU MEXIQUE',
'INTERNATIONAL WATERS','LOCALITY UNKNOWN','NORTH PACIFIC','NORTH PACIFIC OCEAN') and clavepaismapa = "MX"
and zonamapa not like "%ROCAS ALIJOS%";

/* Eliminamos los que no sean de Estados Unidos, Mexico , centroamerica y el caribe., y se dejan los que se marcaron en el paso anterior por caer dentro de mexico pero con otro nombre
en paisoriginal */
delete from geoportal_trabajo.InformacionGeoportal
where paisoriginal not in ("MEXICO","ANGUILA","ANTIGUA Y BARBUDA","ARUBA","BAHAMAS","BARBADOS","BELICE","BONAIRE, SAN EUSTAQUIO Y SABA","COLOMBIA","COSTA RICA","CUBA",
"CURAZAO","DOMINICA","EL SALVADOR","ESTADOS UNIDOS DE AMERICA","GRANADA","GUADALUPE","GUATEMALA","HAITI","HONDURAS","ISLAS CAIMAN","ISLAS TURKS Y CAICOS",
"ISLAS ULTRAMARINAS MENORES DE ESTADOS UNIDOS","ISLAS VIRGENES (BRITANICAS)","ISLAS VIRGENES (ESTADOS UNIDOS)","JAMAICA","MARTINICA","MONTSERRAT","NICARAGUA","PANAMA",
"PUERTO RICO","REPUBLICA DOMINICANA","SAN BARTOLOME","SAN CRISTOBAL Y NIEVES","SAN MARTIN (PARTE FRANCESA)","SAN MARTIN (PARTE HOLANDESA)","SAN VICENTE Y LAS GRANADINAS",
"SANTA LUCIA","TRINIDAD Y TOBAGO","","BELIZE","ANGUILLA","ANTIGUA AND BARBUDA","BONAIRE, SINT EUSTATIUS AND SABA","BRITISH VIRGIN ISLANDS","CAYMAN ISLANDS","CURAÇAO",
"DOMINICAN REPUBLIC","GRENADA","GUADELOUPE","MARTINIQUE","SAINT KITTS AND NEVIS","SAINT LUCIA","SAINT VINCENT AND THE GRENADINES","SAINT-BARTHÉLEMY","SAINT-MARTIN",
"SINT MAARTEN","TRINIDAD AND TOBAGO","TURKS AND CAICOS ISLANDS","UNITED STATES","UNITED STATES MINOR OUTLYING ISLANDS","VIRGIN ISLANDS, U.S.","CLIPPERTON ISLAND","ISLA CLIPPERTON","CLIPPERTON",
"CP","CPT","AI","AIA","AG","ATG","AW","ABW","BB","BRB","BZ","BLZ","BQ","BES","CO","COL","CR","CRI","CU","CUB","CW","CUW","DM","DMA","SV","SLV","GD","GRD",
"GP","GLP","GT","GTM","HT","HTI","HN","HND","JM","JAM","MQ","MTQ","MX","MEX","MS","MSR","NI","NIC","PA","PAN","PR","PRI","KN","KNA","LC","LCA","VC","VCT",
"TT","TTO","US","USA")
 and (paismapa not in ("MEXICO","ANGUILA","ANTIGUA Y BARBUDA","ARUBA","BAHAMAS","BARBADOS","BELICE","BONAIRE, SAN EUSTAQUIO Y SABA","COLOMBIA","COSTA RICA","CUBA","CURAZAO","DOMINICA","EL SALVADOR","ESTADOS UNIDOS DE AMERICA",
"GRANADA","GUADALUPE","GUATEMALA","HAITI","HONDURAS","ISLAS CAIMAN","ISLAS TURKS Y CAICOS","ISLAS ULTRAMARINAS MENORES DE ESTADOS UNIDOS","ISLAS VIRGENES (BRITANICAS)","ISLAS VIRGENES (ESTADOS UNIDOS)","JAMAICA","MARTINICA",
"MONTSERRAT","NICARAGUA","PANAMA","PUERTO RICO","REPUBLICA DOMINICANA","SAN BARTOLOME","SAN CRISTOBAL Y NIEVES","SAN MARTIN (PARTE FRANCESA)","SAN MARTIN (PARTE HOLANDESA)","SAN VICENTE Y LAS GRANADINAS","SANTA LUCIA",
"TRINIDAD Y TOBAGO","ISLA CLIPPERTON","FRANCIA")
OR (paismapa = "FRANCIA" AND (localidad not like '%clipperton%'
or estadooriginal not like '%clipperton%'
or paisoriginal not like '%clipperton%'
or municipiooriginal not like '%clipperton%'
or paismapa not like '%clipperton%'
or estadomapa not like '%clipperton%'))) and eliminar is null;

/* Eliminamos los registros de alaska y hawaii que traen como pais ESTADOS UNIDOS DE AMERICA */

delete from geoportal_trabajo.InformacionGeoportal
where paisoriginal = "ESTADOS UNIDOS DE AMERICA" and estadooriginal in ("ALASKA","HAWAII");

delete from geoportal_trabajo.InformacionGeoportal
where paismapa = "ESTADOS UNIDOS DE AMERICA" and estadomapa in ("ALASKA","HAWAII");


/* Los siguientes dos qrys se deben ejecutar teniendo seleccionada la base de datos geoportal_trabajo, de lo contrario marca un error. */
/* Eliminamos de informacionGeoportal todos los registros que esten en EjemplaresNoDebenAparecerGeoportal 
NOTA: el delete NO TIENE WHERE por que elimina apartir de una tabla creada con los elementos a eliminar,
2023-08-21 vimos que la mayoria llegan a orden y ese puede ser el motivo por el que pidideron eliminarlos */
delete geoportal_trabajo.InformacionGeoportal from geoportal_trabajo.EjemplaresNoDebenAparecerGeoportal inner join
geoportal_trabajo.InformacionGeoportal  on geoportal_trabajo.EjemplaresNoDebenAparecerGeoportal.llaveejemplar = geoportal_trabajo.InformacionGeoportal.llaveejemplar;

delete geoportal_trabajo.InformacionGeoportal from geoportal_trabajo.ejemplarParaQuitarGeoportal inner join
geoportal_trabajo.InformacionGeoportal on geoportal_trabajo.ejemplarParaQuitarGeoportal.llaveejemplar = geoportal_trabajo.InformacionGeoportal.llaveejemplar;

/* Eliminamos lo que no sea de Libre acceso */

/* 2023-08-21 Se quito el filtro de CONAFOR  y de  no proporcionar razas */
delete from geoportal_trabajo.InformacionGeoportal where tiporestriccion not in ('Libre acceso',
'Libre acceso, excepto los siguientes campos (que corresponden a información genética): Microsatellite Bcf01 al Microsatellite Bcf08 y Bcf01 al Bcf08');

/* Eliminamos lo que tenga una nota en el campo cuarentena */
delete from geoportal_trabajo.InformacionGeoportal
where cuarentena<>"";

/* Eliminamos los registros de naturalista con coordenadas obscurecidas */
delete from geoportal_trabajo.InformacionGeoportal where obsusoinfo like '%Coordenada obscurecida%';

/* Eliminamos registros de familias y generos erroneos. */

 

/* De aqui en adelante es para eliminar registros malos a mano. */
delete i1.* FROM geoportal_trabajo.po_eliminargeoportal_inaturalist20161116 i inner join geoportal_trabajo.InformacionGeoportal i1 on i.idejemplar=i1.llaveejemplar;

delete i1.* FROM geoportal_trabajo.po_eliminargeoportal20161025 i inner join geoportal_trabajo.InformacionGeoportal i1 on i.idejemplar=i1.llaveejemplar;

delete from geoportal_trabajo.InformacionGeoportal
where especie="Falco deiroleucus" or especievalida="Falco deiroleucus" or especievalidabusqueda="Falco deiroleucus";

/* *******************************************************************************************************************************************************************************************************************************************************************************************/
ALTER TABLE snib.informaciongeoportal_siya rename snib.informaciongeoportal_siyahistorico;

-- geberamos la tabla ejemplar_referenciatax

drop table if exists geoportal_trabajo.ejemplar_referenciatax;

create table geoportal_trabajo.ejemplar_referenciatax
select llaveejemplar,if(n.comentarioscat like '%completamente con CAT%',t.SistClasCatDiccTaxon,if(n.comentarioscat like '%completamente con otra fuente%','Catalog Of Life Checklist, 2022','')) as referenciatax
from snib.ejemplar_curatorial e inner join geoportal_trabajo.nombre1 n on e.llavenombre=n.llavenombre
left join catalogocentralizado._TransformaTablaNombre t on n.idnombrecat=t.IdCAT
where e.estadoregistro='';

ALTER TABLE geoportal_trabajo.ejemplar_referenciatax ADD PRIMARY KEY(llaveejemplar);

/* De Aqui en adelante se crea la tabla informaciongeoportal_siya */
CREATE TABLE snib.informaciongeoportal_siya (
  `idejemplar` varchar(32) NOT NULL DEFAULT '' COMMENT 'Clave generada por la CONABIO que identifica de manera única al ejemplar. Se asigna en el momento en que el ejemplar se integra al SNIB.',
  `region` varchar(150) NOT NULL DEFAULT '' COMMENT 'Especifica el país, estado y municipio o su división política equivalente, registrado por el colector, observador o por la CONABIO (para aquellos ejemplares que ha georreferido).',
  `localidad` varchar(2048) NOT NULL DEFAULT '' COMMENT 'Referencia geográfica que describe la ubicación del lugar de recolecta u observación.',
  `longitud` double DEFAULT NULL COMMENT 'Longitud de la coordenada geográfica del sitio de recolecta u observación del ejemplar.',
  `latitud` double DEFAULT NULL COMMENT 'Latitud de la coordenada geográfica del sitio de recolecta u observación del ejemplar.',
  `datum` varchar(50) NOT NULL DEFAULT '' COMMENT 'Sistema de referencia geodésico a partir del cual se obtuvo la coordenada geográfica del sitio de recolecta u observación del ejemplar.',
  `geovalidacion` varchar(200) NOT NULL DEFAULT '' COMMENT 'Resultado de la validación geográfica realizada por la CONABIO, esta se realiza hasta en cuatro niveles país/estado/municipio/localidad.',
  `paismapa` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre del país donde se ubica la coordenada geográfica registrada para el ejemplar, respecto a los mapas de división política de México incluyendo la zona económica exclusiva y los mapas de división política de otros países para la zona continental, utilizados para la validación geográfica realizada por la CONABIO.',
  `idestadomapa` mediumint(8) unsigned DEFAULT NULL COMMENT 'Clave del municipio donde se ubica la coordenada geográfica registrada para el ejemplar, respecto al mapa de división política de México y de otros países utilizados para la validación geográfica realizada por la CONABIO.',
  `claveestadomapa` varchar(10) NOT NULL DEFAULT '' COMMENT 'Clave del estado respecto al mapa de división política de México utilizado para la validación geográfica realizada por la CONABIO.',
  `estadomapa` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre del estado o división política equivalente donde se ubica la coordenada geográfica registrada para el ejemplar, respecto al mapa de división política de México y de otros países utilizados para la validación geográfica realizada por la CONABIO.',
  `mt24idestadomapa` mediumint(8) unsigned DEFAULT NULL COMMENT 'Identificador único del nombre del estado donde se ubica la coordenada geográfica registrada para el ejemplar frente al cual se extiende la franja de 12 millas náuticas del mar territorial y 12 millas náuticas de la zona contigua de México.',
  `mt24claveestadomapa` varchar(10) NOT NULL DEFAULT ''  COMMENT 'Clave del estado donde se ubica la coordenada geográfica registrada para el ejemplar, frente al cual se extiende la franja de 12 millas náuticas del mar territorial y 12 millas náuticas de la zona contigua de México.',
  `mt24nombreestadomapa` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre del estado donde se ubica la coordenada geográfica registrada para el ejemplar, frente al cual se extiende la franja de 12 millas náuticas del mar territorial y 12 millas náuticas de la zona contigua de México.',
  `idmunicipiomapa` int(10) unsigned DEFAULT NULL COMMENT 'Identificador único del nombre del municipio en donde se ubica la coordenada geográfica registrada para el ejemplar, respecto al mapa de división política municipal de México utilizado para la validación geográfica realizada por la CONABIO.',
  `clavemunicipiomapa` varchar(10) NOT NULL DEFAULT '' COMMENT 'Clave del municipio respecto al mapa de división política municipal de México utilizado para la validación geográfica realizada por la CONABIO.',
  `municipiomapa` varchar(80) NOT NULL DEFAULT '' COMMENT 'Nombre del municipio, en donde se ubica la coordenada geográfica registrada para el ejemplar, respecto al mapa de división política municipal de México utilizado para la validación geográfica realizada por la CONABIO.',
  `mt24idmunicipiomapa` int(10) unsigned DEFAULT NULL COMMENT 'Identificador único del nombre del estado donde se ubica la coordenada geográfica registrada para el ejemplar frente al cual se extiende la franja de 12 millas náuticas del mar territorial y 12 millas náuticas de la zona contigua de México.',
  `mt24clavemunicipiomapa` varchar(10) NOT NULL DEFAULT '' COMMENT 'Clave del municipio donde se ubica la coordenada geográfica registrada para el ejemplar, frente al cual se extiende la franja de 12 millas náuticas del mar territorial y 12 millas náuticas de la zona contigua de México.',
  `mt24nombremunicipiomapa` varchar(80) NOT NULL DEFAULT '' COMMENT 'Nombre del municipio donde se ubica la coordenada geográfica registrada para el ejemplar frente al cual se extiende la franja de 12 millas náuticas del mar territorial y 12 millas náuticas de la zona contigua de México.',
  `incertidumbreXY` int(11) DEFAULT NULL COMMENT 'Valor de incertidumbre calculado para las coordenadas obtenidas usando el método punto-radio.',
  `altitudmapa` smallint(6) DEFAULT NULL COMMENT 'Altitud donde se ubica la coordenada geográfica obtenida del modelo de elevación ASTER GDEM2.',
  `usvserieI` varchar(100) NOT NULL DEFAULT '' COMMENT 'Especifica el tipo de vegetación y uso del suelo donde se ubica la coordenada geográfica de acuerdo con el mapa de la serie I del INE-INEGI.',
  `usvserieII` varchar(100) NOT NULL DEFAULT '' COMMENT 'Especifica el tipo de vegetación y uso del suelo donde se ubica la coordenada geográfica de acuerdo con el mapa de la serie II del INEGI.',
  `usvserieIII` varchar(100) NOT NULL DEFAULT '' COMMENT 'Especifica el tipo de vegetación y uso del suelo donde se ubica la coordenada geográfica de acuerdo con el mapa de la serie III del INEGI.',
  `usvserieIV` varchar(100) NOT NULL DEFAULT '' COMMENT 'Especifica el tipo de vegetación y uso del suelo donde se ubica la coordenada geográfica de acuerdo con el mapa de la serie IV del INEGI.',
  `usvserieV` varchar(100) NOT NULL DEFAULT '' COMMENT 'Especifica el tipo de vegetación y uso del suelo donde se ubica la coordenada geográfica de acuerdo con el mapa serie V del INEGI.',
  `usvserieVI` varchar(100) NOT NULL DEFAULT '' COMMENT 'Especifica el tipo de vegetación y uso del suelo donde se ubica la coordenada geográfica de acuerdo con el mapa serie VI del INEGI 2016.',
  `usvserieVII` varchar(100) NOT NULL DEFAULT '' COMMENT 'Especifica el tipo de vegetación y uso del suelo donde se ubica la coordenada geográfica de acuerdo con el mapa serie VII del INEGI.',
  `usvINEGI` varchar(100) NOT NULL DEFAULT '' COMMENT 'Nombre del tipo de vegetación según el sistema de Rzedowski o descriptor de la actividad humana.',
  `vegetacionserenanalcms` varchar(70) NOT NULL DEFAULT '' COMMENT 'Vegetación para paises de snib sin fronteras',
  `idanpfederal1` mediumint(8) unsigned DEFAULT NULL COMMENT 'Identificador de la Área Natural Protegida (ANP) asociada al ejemplar.',
  `idanpfederal2` mediumint(8) unsigned DEFAULT NULL COMMENT 'Identificador de la segunda Área Natural Protegida (ANP) asociada al ejemplar.',
  `anp` varchar(250) NOT NULL DEFAULT '' COMMENT 'Especifica la jurisdicción y nombre del área natural protegida (ANP) donde se ubica la coordenada geográfica registrada para el ejemplar respecto a mapas de México de ANP.' ,
  `grupobio` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre utilizado para agrupar taxones con características biológicas generales similares asignado por la CONABIO.',
  `subgrupobio` varchar(250) NOT NULL DEFAULT '' COMMENT 'Nombre utilizado para agrupar taxones con características biológicas similares asignado por la CONABIO; pueden incluir nombres genéricos o el nombre común de la especie.',
  `formadecrecimiento` varchar(100) NOT NULL DEFAULT '' COMMENT 'Forma o aspecto que presenta una planta en su etapa madura: hierba, árbol, arbusto, y bejuco entre otros.',
  `idnombrecatvalido` varchar(50) NOT NULL DEFAULT '' COMMENT 'Identificador del nombre válido en el catálogo de CONABIO.',
  `idnombrecat` varchar(50) NOT NULL DEFAULT '' COMMENT 'Identificador del nombre del ejemplar en el catálogo de CONABIO. Dependiendo de la categoría taxonómica en la cual fue determinado el ejemplar, puede corresponder al identificador de: Clase, Orden, Familia, Género o Especie.',
  `endemismo` enum('','Cuasiendémica','Endémica','Semiendémica') NOT NULL DEFAULT '' COMMENT 'Indica si el taxón tiene una distribución en México considerada como endémica, cuasiendémica o semiendémica, es decir, es originaria de un área geográfica limitada y solo está presente de manera natural en dicha área.',
  `ambiente` varchar(100) NOT NULL DEFAULT '' COMMENT 'Medio donde el ejemplar fue recolectado u observado.',
  `validacionambiente` varchar(100) NOT NULL DEFAULT '' COMMENT 'Indica si el resultado de la validación geográfica del ejemplar coincide con el ambiente registrado.',
  `reino` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre científico del reino en el que se ubica el ejemplar. La CONABIO realizó limpieza de este campo mediante la corrección de errores de escritura y de datos que no corresponden con el campo.',
  `phylumdivision` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre científico del phylum o división en el que se ubica el ejemplar. La CONABIO realizó limpieza de este campo mediante la corrección de errores de escritura y de datos que no corresponden con el campo.',
  `clase` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre científico de la clase en la que se ubica el ejemplar. La CONABIO realizó limpieza de este campo mediante la corrección de errores de escritura y de datos que no corresponden con el campo.',
  `orden` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre científico del orden en el que se ubica el ejemplar. La CONABIO realizó limpieza del orden original en este campo, mediante la corrección de errores de escritura y la estandarización a sistemas de clasificación reconocidos por la comunidad científica.',
  `familia` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre científico de la familia en la que se ubica el ejemplar. La CONABIO realizó limpieza de la familia original en este campo, mediante la corrección de errores de escritura y la estandarización a sistemas de clasificación reconocidos por la comunidad científica.',
  `genero` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre científico del género en el que se ubica el ejemplar. La CONABIO realizó limpieza de este campo mediante la corrección de errores de escritura y de datos que no corresponden con el campo así como la estandarización a sistemas de clasificación reconocidos por la comunidad científica.',
  `especie` varchar(100) NOT NULL DEFAULT '' COMMENT 'Nombre de la especie (binomio, trinomio, etc.) en la cual se determinó el ejemplar. La CONABIO realizó limpieza de este campo mediante la corrección de escritura y de datos que no corresponden con el campo.',
  `calificadordeterminacion` varchar(100) NOT NULL DEFAULT '' COMMENT 'Anotación acerca de la incertidumbre en la identificación taxonómica del ejemplar.',
  `categoriainfraespecie` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre de la categoría taxonómica correspondiente a alguna infraespecífica.',
  `categoriainfraespecie2` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre de la categoría taxonómica correspondiente a alguna subinfraespecífica.',
  `autor` longtext NOT NULL COMMENT 'Autor(es) y año de publicación de la descripción del género, especie (binomio, trinomio, etc.), dependiendo a que nivel se encuentre determinado el ejemplar.',
  `estatustax` varchar(20) NOT NULL DEFAULT '' COMMENT 'Estatus taxonómico del género o especie (binomio, trinomio, etc.) dependiendo a que nivel se encuentre determinado el ejemplar y de acuerdo con los catálogos de autoridades taxonómicas de la CONABIO o de otras referencias especializadas.',
  `reftax` varchar(255) NOT NULL DEFAULT '' COMMENT 'Autor(es) y año de publicación del catálogo de autoridad, listado, diccionario, sistema de clasificación (en el caso de familia) o de otras referencias especializadas usadas por la CONABIO para validar el taxón (familia, género, especie).',
  `taxonvalidado` varchar(2) NOT NULL DEFAULT '' COMMENT 'Indica si el nombre al que se determinó el ejemplar se pudo validar con los catálogos de autoridades taxonómicas de la CONABIO o en otras referencias especializadas.',
  `reinovalido` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre científico del Reino en el que se ubica el nombre válido del taxón correspondiente al ejemplar y que está reconocido en los catálogos de autoridades taxonómicas de la CONABIO o en otras referencias especializadas.',
  `phylumdivisionvalido` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre científico de la división o el phylum en el que se ubica el nombre válido del taxón correspondiente al ejemplar y que está reconocido en los catálogos de autoridades taxonómicas de la CONABIO o en otras referencias especializadas.',
  `clasevalida` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre científico de la clase en la que se ubica el nombre válido del taxón correspondiente al ejemplar y que está reconocido en los catálogos de autoridades taxonómicas de la CONABIO o en otras referencias especializadas.',
  `ordenvalido` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre científico del orden en el que se ubica el nombre válido del taxón correspondiente al ejemplar y que está reconocido en los catálogos de autoridades taxonómicas de la CONABIO o en otras referencias especializadas.',
  `familiavalida` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre científico de la familia en la que se ubica el nombre válido del taxón correspondiente al ejemplar y que está reconocido en los catálogos de autoridades taxonómicas de la CONABIO o en otras referencias especializadas.',
  `generovalido` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre científico del género en el que se ubica el nombre válido del taxón correspondiente al ejemplar y que está reconocido en los catálogos de autoridades taxonómicas de la CONABIO o en otras referencias especializadas.',
  `especievalida` varchar(100) NOT NULL DEFAULT '' COMMENT 'Nombre válido de la especie (binomio, trinomio, etc.) reconocida en los catálogos de autoridades taxonómicas de la CONABIO o en otras referencias especializadas.',
  `categoriainfraespecievalida` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre de la categoría taxonómica correspondiente a la infraespecífica del nombre válido.',
  `categoriainfraespecie2valida` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre de la categoría taxonómica correspondiente a la subinfraespecífica del nombre válido.',
  `especievalidabusqueda` varchar(100) NOT NULL DEFAULT '' COMMENT 'Binomio generovalido - epiteto especifico valido utilizado para busquedas',
  `autorvalido` mediumtext NOT NULL COMMENT 'Nombre del autor o autores y año de la descripción del género, especie (binomio, trinomio, etc.) válida en catálogos de autoridades taxonómicas de la CONABIO o en otras referencias especializadas.',
  `reftaxvalido` varchar(255) NOT NULL DEFAULT '' COMMENT 'Autor(es) y año de publicación del catálogo de autoridad, listado o diccionario o de otras referencias especializadas usadas por la CONABIO que respaldan el nombre válido del taxón (familia, género, especie).',
  `categoriavalidocatscat` varchar(30) NOT NULL DEFAULT '' COMMENT '',  
  `nombrevalidocatscat` varchar(100) NOT NULL DEFAULT '' COMMENT '',
  `taxonextinto` enum('','SI','NO') NOT NULL DEFAULT '' COMMENT 'Indica si corresponde a un taxón (especie o grupo taxonómico superior como familia, orden, etc) cuya desaparición se ha confirmado.',
  `ejemplarfosil` enum('','SI','NO') NOT NULL DEFAULT '' COMMENT 'Indica si el ejemplar es fósil.',
  `nombrecomun` text NOT NULL COMMENT 'Nombre común reconocido para el taxón en los catálogos de autoridades taxonómicas de la CONABIO.',
  `categoriaresidenciaaves` varchar(100) NOT NULL DEFAULT '' COMMENT 'Indica el tipo de residencia de las aves respecto al sitio y a la temporada del año en la que fue colectado, observado o reportado el ejemplar.',
  `prioritaria` varchar(100) NOT NULL DEFAULT '' COMMENT 'Especies utilizadas para representar a otras especies o aspectos significativos del ambiente para conseguir un objetivo determinado de conservación.',
  `nivelprioridad` enum('','Alta','Media','Menor') NOT NULL DEFAULT '' COMMENT 'Nivel de prioridad asignado a la especie para su protección y conservación.',
  `exoticainvasora` varchar(50) NOT NULL DEFAULT '' COMMENT 'Indica si una especie está catalogada como exótica, exótica invasora o criptogénica para México.',
  `nom059` varchar(512) NOT NULL DEFAULT '' COMMENT 'Indica la categoría de riesgo conforme a la NOM-059-SEMARNAT de la especie o la categoría infraespecífica.',
  `cites` varchar(512) NOT NULL DEFAULT '' COMMENT 'Indica el grado de protección contra el comercio ilegal conforme a la Convención sobre el Comercio Internacional de Especies Amenazadas de Fauna y Flora Silvestres.',
  `iucn` varchar(1024) NOT NULL DEFAULT '' COMMENT 'Indica el estado de conservación de la especie conforme a la lista roja de la Unión Internacional para la Conservación de la Naturaleza (IUCN).',
  `coleccion` varchar(150) NOT NULL DEFAULT '' COMMENT 'Siglas y nombre de la colección que resguarda al ejemplar.',
  `institucion` varchar(255) NOT NULL DEFAULT '' COMMENT 'Siglas y nombre de la institución que custodia la colección científica, o que avala el registro de un ejemplar.',
  `paiscoleccion` varchar(50) NOT NULL DEFAULT '' COMMENT 'País donde se localiza la colección o la institución que resguarda el registro observado o reportado.',
  `numcatalogo` varchar(100) NOT NULL DEFAULT '' COMMENT 'Identificador único del ejemplar en la colección biológica, se le asigna cuando se incorpora a esta.',
  `numcolecta` varchar(100) NOT NULL DEFAULT '' COMMENT 'Identificador asignado por el recolector u observador para cada evento de recolecta u observación.',
  `procedenciaejemplar` ENUM('','HumanObservation','PreservedSpecimen','FossilSpecimen','MaterialCitation','Occurrence','MaterialSample','MachineObservation','LivingSpecimen') NOT NULL DEFAULT '' COMMENT 'Indica si el ejemplar proviene de un evento de recolecta, observación o de un reporte.',
  `determinador` varchar(512) NOT NULL DEFAULT '' COMMENT 'Nombre o abreviado de la persona que realizó la determinación del ejemplar.',
  `fechadeterminacion` varchar(10) NOT NULL DEFAULT '' COMMENT 'Es la fecha en la que se realizó la determinación del ejemplar.',
  `diadeterminacion` tinyint(4) DEFAULT NULL COMMENT 'Día en que se realizó la determinación del ejemplar.',
  `mesdeterminacion` tinyint(4) DEFAULT NULL COMMENT 'Mes en que se realizó la determinación del ejemplar.',
  `aniodeterminacion` smallint(6) DEFAULT NULL COMMENT 'Año en que se realizó la determinación del ejemplar.',
  `colector` varchar(512) NOT NULL DEFAULT '' COMMENT 'Nombre o abreviado de la persona o grupo que participó en la recolecta u observación del ejemplar.',
  `fechacolecta` varchar(10) NOT NULL DEFAULT '' COMMENT 'Es la fecha del evento de recolecta u observación del ejemplar.',
  `diacolecta` tinyint(4) DEFAULT NULL COMMENT 'Día del evento de recolecta u observación del ejemplar.',
  `mescolecta` tinyint(4) DEFAULT NULL COMMENT 'Mes del evento de recolecta u observación del ejemplar.',
  `aniocolecta` smallint(6) DEFAULT NULL COMMENT 'Año del evento de recolecta u observación del ejemplar.',
  `tipo` varchar(60) NOT NULL DEFAULT '' COMMENT 'Tipo nomenclatural del ejemplar.',
  `obsusoinfo` varchar(512) NOT NULL DEFAULT '' COMMENT 'Inconsistencias detectadas en los datos o información complementaria para el uso de los datos.',
  `probablelocnodecampo` enum('','SI','NO') NOT NULL DEFAULT '' COMMENT 'Campo marcado para ejemplares recolectados en probables hábitats no naturales.',
  `zonamapa` varchar(150) NOT NULL DEFAULT '' COMMENT 'Nombre de la zona geográfica y/o tipo de rasgo geográfico donde se ubica la coordenada geográfica.',
  `paiscodvalidacion` tinyint(4) DEFAULT NULL COMMENT 'Código correspondiente al estatus de validación geográfica a nivel de país.',
  `edocodvalidacion` tinyint(4) DEFAULT NULL COMMENT 'Código correspondiente al estatus de la validación geográfica a nivel de estado.',
  `mpiocodvalidacion` tinyint(4) DEFAULT NULL COMMENT 'Código correspondiente al estatus de la validación geográfica a nivel de municipio.',
  `localidadcodvalidacion` tinyint(4) DEFAULT NULL COMMENT 'Código correspondiente al estatus de la validación geográfica a nivel de localidad.',
  `cuarentena` varchar(255) NOT NULL DEFAULT '' COMMENT 'Comentario resultante de una revisión realizada por la CONABIO que indica si el registro cuenta con alguna inconsistencia de información.',
  `proyecto` varchar(50) NOT NULL DEFAULT '' COMMENT 'Referencia que identifica al proyecto.',
  `clavebasedatos` varchar(150) NOT NULL DEFAULT '' COMMENT 'Referencia que identifica la versión final de la base de datos que se integra al SNIB.',
  `identificacionarchivo` varchar(60) NOT NULL DEFAULT '' COMMENT 'Identifica las diferentes bases de datos finales de un mismo proyecto.',
  `fuenteoriginal` varchar(50) NOT NULL DEFAULT '' COMMENT 'Indica la fuente original de información del ejemplar incorporado a una nueva base de datos en el SNIB.',
  `urlejemplar` varchar(255) NOT NULL DEFAULT '' COMMENT 'Dirección de internet que permite consultar la información del ejemplar proporcionada en las bases de datos originales y la estandarizada por la CONABIO de tipo curatorial, taxonómica y geográfica.',
  `urlorigen` varchar(255) NOT NULL DEFAULT '' COMMENT 'Dirección de internet desde la cual originalmente se descargó la información del ejemplar en las páginas de GBIF o Naturalista.',
  `licenciauso` varchar(255) NOT NULL DEFAULT '' COMMENT 'Licencia de uso de la información del ejemplar.',
  `tiporestriccion` varchar(150) NOT NULL DEFAULT '' COMMENT 'Descripción de la restricción de uso de la información.',
  `comentarioscat` varchar(1024) NOT NULL DEFAULT '' COMMENT 'Indica detalle de la validación del nombre en el catalogo de nombres de la CONABIO.',
  `comentarioscatvalido` varchar(1024) NOT NULL DEFAULT '' COMMENT 'Indica detalle de la validación del nombre válido en el catalogo de nombres de la CONABIO.',
  `homonimosgenero` varchar(512) NOT NULL DEFAULT '' COMMENT 'Indica los homónimos a nivel género del nombre válidado con los catálogos de autoridades taxonómicas de la CONABIO.',
  `homonimosespecie` TEXT NOT NULL COMMENT 'Indica los homónimos a nivel especie del nombre válidado con los catálogos de autoridades taxonómicas de la CONABIO.',
  `homonimosinfraespecie` varchar(255) NOT NULL DEFAULT '' COMMENT 'Indica los homónimos a nivel infraespecie del nombre válidado con los catálogos de autoridades taxonómicas de la CONABIO.',
  `homonimosgenerocatvalido` varchar(255) NOT NULL DEFAULT '' COMMENT 'Indica los homónimos a nivel género del taxón válido en el que se ubica el ejemplar.',
  `homonimosespeciecatvalido` TEXT NOT NULL COMMENT 'Indica los homónimos a nivel especie del taxón válido en el que se ubica el ejemplar.',
  `homonimosinfraespeciecatvalido` varchar(255) NOT NULL DEFAULT '' COMMENT 'Indica los homónimos a nivel infraespecie del taxón válido en el que se ubica el ejemplar.',
  `distribucionnom2010` enum('','endémica','no endémica') NOT NULL DEFAULT '' COMMENT 'Distribución del taxón reportada por la NOM-059-SEMARNAT.',
  `idmias` varchar(32) NOT NULL DEFAULT '' COMMENT 'Llave para agrupar los campos latitud, longitud, nombrepaismapa, nombreestadomapa y nombremunicipiomapa.',
  `regionmarinamapa` varchar(100) NOT NULL DEFAULT '' COMMENT 'Área geográfica donde se ubica la coordenada geográfica.',
  `nombrerasgogeograficomapa` varchar(100) NOT NULL DEFAULT '' COMMENT 'Nombre del rasgo geográfico donde se ubica la coordenada geográfica.',
  `tiporasgogeograficomapa` varchar(50) NOT NULL DEFAULT '' COMMENT 'Tipo de rasgo geográfico donde se ubica la coordenada geográfica.',
  `mt24mapa` varchar(100) NOT NULL DEFAULT '' COMMENT 'Nombre del estado costero asignado como referencia de ubicación del mar territorial y zona contigua 24 mi náuticas.',
  `noaplicavegetacionmapa` varchar(50) NOT NULL DEFAULT '' COMMENT 'Información que no corresponde a descripciones de vegetación donde se ubica la coordenada geográfica.',
  `distmpio` int(11) DEFAULT NULL COMMENT 'Indica la distancia que existe entre la ubicación de la coordenada y el municipio asociado al ejemplar.',
  `codificacion` smallint(6) DEFAULT NULL COMMENT 'Código que indica el resultado de la validación a nivel país, estado, municipio y localidad.',
  `procesovalidacion` varchar(70) NOT NULL DEFAULT '' COMMENT 'Clave referente al proceso y resultado de la validación geográfica a nivel de país, estado, municipio y localidad.',
  `estadoregistro` varchar(255) NOT NULL DEFAULT '' COMMENT 'Indica si el ejemplar tiene el estatus de eliminado o en proceso de integración.',
  `fuente` varchar(50) NOT NULL DEFAULT '' COMMENT 'Indica la fuente original de información del ejemplar incorporado a una nueva base de datos (campo proyecto) en el SNIB.',
  `formadecitar` text NOT NULL COMMENT 'Forma de citar los datos al hacer uso de estos o parte de los mismos.',
  `urlproyecto` varchar(255) NOT NULL DEFAULT '' COMMENT 'Dirección de internet en la cual se puede consultar la información del proyecto.',
  `categoriataxonomica` varchar(50) NOT NULL DEFAULT '' COMMENT 'Ultima categoría a la que llega el registro',
  `geoportal` tinyint(1) DEFAULT NULL COMMENT 'Indica si la información del ejemplar esta publicada en el geoportal.',
  `ultimafechaactualizacion` date DEFAULT NULL COMMENT 'Fecha de última actualización de los datos.',
  `version` varchar(7) NOT NULL DEFAULT '' COMMENT 'Versión que corresponde a las decisiones de los procesos de revisión aplicados a los datos en la CONABIO, así como, la información de referencia (mapas, catálogos, etc.) que se utiliza para realizar dicha revisión al integrar al SNIB. Cada vez que se cambien estás decisiones afectando la revisión de los datos, se cambiará la versión y se publicará el documento que describe los nuevos procesos y referencias correspondientes a la versión citada en este campo.',
  `paisoriginal` varchar(50) NOT NULL DEFAULT '' COMMENT 'Nombre del país en el que el ejemplar fue recolectado u observado.',
  `estadooriginal` varchar(55) NOT NULL DEFAULT '' COMMENT 'Nombre del estado o división política equivalente en la que el ejemplar fue recolectado u observado.',
  `municipiooriginal` varchar(80) NOT NULL DEFAULT '' COMMENT 'Nombre del municipio en el que el ejemplar fue recolectado u observado.',
  `llavecontrolcambios` varchar(32) NOT NULL DEFAULT ''
) ENGINE=Aria DEFAULT CHARSET=utf8 COMMENT='En esta tabla se almacenan los datos de la base de individuos proporcionados a la Subcoordinadora en Información y Análisis.';

/* Nuevo agregado el 01/02/2023 para evitar generar dos veces la misma tabla */

insert into snib.informaciongeoportal_siya(idejemplar,region,localidad,longitud,latitud,datum,geovalidacion,paismapa,idestadomapa,claveestadomapa,estadomapa,mt24idestadomapa,mt24claveestadomapa,mt24nombreestadomapa,idmunicipiomapa,clavemunicipiomapa,municipiomapa,mt24idmunicipiomapa,mt24clavemunicipiomapa,mt24nombremunicipiomapa,incertidumbreXY,altitudmapa,usvserieI,usvserieII,usvserieIII,usvserieIV,usvserieV,usvserieVI,usvserieVII,usvINEGI,vegetacionserenanalcms,idanpfederal1,idanpfederal2,anp,grupobio,subgrupobio,formadecrecimiento,idnombrecatvalido,idnombrecat,endemismo,ambiente,validacionambiente,reino,phylumdivision,clase,orden,familia,genero,especie,calificadordeterminacion,categoriainfraespecie,categoriainfraespecie2,autor,estatustax,reftax,taxonvalidado,reinovalido,phylumdivisionvalido,clasevalida,ordenvalido,familiavalida,generovalido,especievalida,categoriainfraespecievalida,categoriainfraespecie2valida,especievalidabusqueda,autorvalido,reftaxvalido,categoriavalidocatscat,nombrevalidocatscat,taxonextinto,ejemplarfosil,nombrecomun,categoriaresidenciaaves,prioritaria,nivelprioridad,exoticainvasora,nom059,cites,iucn,coleccion,institucion,paiscoleccion,numcatalogo,numcolecta,procedenciaejemplar,determinador,fechadeterminacion,diadeterminacion,mesdeterminacion,aniodeterminacion,colector,fechacolecta,diacolecta,mescolecta,aniocolecta,tipo,obsusoinfo,probablelocnodecampo,zonamapa,paiscodvalidacion,edocodvalidacion,mpiocodvalidacion,localidadcodvalidacion,cuarentena,proyecto,clavebasedatos,identificacionarchivo,fuenteoriginal,urlejemplar,urlorigen,licenciauso,tiporestriccion,comentarioscat,comentarioscatvalido,homonimosgenero,homonimosespecie,homonimosinfraespecie,homonimosgenerocatvalido,homonimosespeciecatvalido,homonimosinfraespeciecatvalido,distribucionnom2010,idmias,regionmarinamapa,nombrerasgogeograficomapa,tiporasgogeograficomapa,mt24mapa,noaplicavegetacionmapa,distmpio,codificacion,procesovalidacion,estadoregistro,fuente,formadecitar,urlproyecto,categoriataxonomica,geoportal,ultimafechaactualizacion,version,paisoriginal,estadooriginal,municipiooriginal,llavecontrolcambios)
select e.llaveejemplar,
concat(case when ro.paisoriginal='' then 'NO DISPONIBLE' else ro.paisoriginal end,
case when ro.estadooriginal not in("","NO DISPONIBLE","UNKNOWN","ND","NO APLICA","NA","INFORMACION NO DISPONIBLE") then
concat(" / ",ro.estadooriginal,case when ro.municipiooriginal not in ("","NO DISPONIBLE","UNKNOWN","ND","NO APLICA","NA","INFORMACION NO DISPONIBLE") then
concat(" / ",ro.municipiooriginal) else '' end) 
else case when ro.municipiooriginal not in ("","NO DISPONIBLE","UNKNOWN","ND","NO APLICA","NA","INFORMACION NO DISPONIBLE") then
concat(" / NO DISPONIBLE / ",ro.municipiooriginal) else '' end end) as region,
l.localidad,
r.longitudconabio as longitud,
r.latitudconabio as latitud,
r.datumconabio as datum,
case when binary p.procesovalidacion like "%L%" and p.procesovalidacion<>"NO APLICA" then 'Válido localidad'
when p.procesovalidacion rlike '_validoB[0-9]{4}' then concat('Válido municipio ',right(p.procesovalidacion,4),' con tolerancia')
when p.procesovalidacion rlike '_valido[0-9]{4}' then concat('Válido municipio ',right(p.procesovalidacion,4))
when binary p.procesovalidacion like '%BP%' and r.estadocodigovalidacion = 10 and r.validacionestado = 'NO APLICA' then concat('Válido país ',right(p.procesovalidacion,4),' con tolerancia. No aplica validación de estado y municipio')
when binary p.procesovalidacion like '%BE%' and r.municipiocodigovalidacion = 0 then concat('Válido estado ',right(p.procesovalidacion,4),' con tolerancia. No válido municipio')
when binary p.procesovalidacion like '%BE%' and r.municipiocodigovalidacion = 10 then concat('Válido estado ',right(p.procesovalidacion,4),' con tolerancia. No procesado municipio')
when binary p.procesovalidacion like '%BP%' and r.estadocodigovalidacion = 10 and r.validacionestado in("sin información","NO PROCESADO") then concat('Válido país ',right(p.procesovalidacion,4),' con tolerancia. No procesado estado y municipio')
when binary p.procesovalidacion like '%BP%' and r.estadocodigovalidacion = 0 and r.municipiocodigovalidacion=10 then concat('Válido país ',right(p.procesovalidacion,4),' con tolerancia. No válido estado y no procesado municipio')
when binary p.procesovalidacion like '%BP%' and r.estadocodigovalidacion = 0 and r.municipiocodigovalidacion=0 then concat('Válido país ',right(p.procesovalidacion,4),' con tolerancia. No válido estado y municipio')
when binary p.procesovalidacion rlike '_no valido_naPEM_[0-9]{4}' then 'No aplica validación de país'
when binary p.procesovalidacion like '%P%' and p.procesovalidacion<>"NO APLICA" and r.estadocodigovalidacion = 10 and r.validacionestado = 'NO APLICA' then concat('Válido país ',right(p.procesovalidacion,4),'. No aplica validación de estado y municipio')
when binary p.procesovalidacion like '%E%' and r.municipiocodigovalidacion = 0 then concat('Válido estado ',right(p.procesovalidacion,4),'. No válido municipio')
when binary p.procesovalidacion like '%E%' and r.municipiocodigovalidacion = 10 then concat('Válido estado ',right(p.procesovalidacion,4),'. No procesado municipio')
when binary p.procesovalidacion like '%P%' and p.procesovalidacion<>"NO APLICA" and r.estadocodigovalidacion = 10 and r.validacionestado in("sin información","NO PROCESADO") then concat('Válido país ',right(p.procesovalidacion,4),'. No procesado estado y municipio')
when binary p.procesovalidacion like '%P%' and p.procesovalidacion<>"NO APLICA" and r.estadocodigovalidacion = 0 and r.municipiocodigovalidacion=10 then concat('Válido país ',right(p.procesovalidacion,4),'. No válido estado y no procesado municipio')
when binary p.procesovalidacion like '%P%' and p.procesovalidacion<>"NO APLICA" and r.estadocodigovalidacion = 0 and r.municipiocodigovalidacion=0 then concat('Válido país ',right(p.procesovalidacion,4),'. No válido estado y municipio')
when binary p.procesovalidacion rlike '_no valido[0-9]{4}' and r.estadocodigovalidacion=10 and r.municipiocodigovalidacion=10 then concat('No válido país ',right(p.procesovalidacion,4),'. No procesado estado y municipio')
when binary p.procesovalidacion rlike '_no valido[0-9]{4}' and r.estadocodigovalidacion=0 and r.municipiocodigovalidacion=10 then concat('No válido país y estado ',right(p.procesovalidacion,4),'. No procesado municipio')
when binary p.procesovalidacion rlike '_no valido[0-9]{4}' and r.estadocodigovalidacion=0 and r.municipiocodigovalidacion=0 then concat('No válido país, estado y municipio ',right(p.procesovalidacion,4))
when p.procesovalidacion like 'sin coordenadas%' then p.procesovalidacion
when p.procesovalidacion = 'NO APLICA' then 'No procesado' else 'No procesado' end as geovalidacion,

rm.nombrepaismapa as paismapa,
rm.idestadomapa,
rm.claveestadomapa,
rm.nombreestadomapa as estadomapa,
m.mt24idestadomapa,
m.mt24claveestadomapa,
m.mt24nombreestadomapa,
rm.idmunicipiomapa,
rm.clavemunicipiomapa,
rm.nombremunicipiomapa as municipiomapa,
m.mt24idmunicipiomapa,
m.mt24clavemunicipiomapa,
m.mt24nombremunicipiomapa,
r.incertidumbreconabio as incertidumbreXY,
r.altitudmapa,
ev.usvserieI,
ev.usvserieII,
ev.usvserieIII,
ev.usvserieIV,
r.usvsV as usvserieV,
r.usvsVI as usvserieVI,
r.usvsVII as usvserieVII,
ev.usvINEGI,
vs.vegetacionserenanalcms,
a.idanpfederal1,
a.idanpfederal2,
case when rm.nombrepaismapa='MEXICO' then
concat(case when a.anpfederales <> "" then concat("Federal» ",a.anpfederales,
case when a.anpestatales <> "" then concat(" | Estatal» ",a.anpestatales,
case when a.anpotras <> "" then concat(" | ",a.anpotras) else '' end) else
case when a.anpotras <> "" then concat(" | ",a.anpotras) else '' end end ) else
case when a.anpestatales <> "" then concat("Estatal» ",a.anpestatales,
case when a.anpotras <> "" then concat(" | ",a.anpotras) else '' end) else
case when a.anpotras <> "" then a.anpotras else '' end end end)
when rm.nombrepaismapa not in('MEXICO','') then
concat(case when a.anpinternacional <> "" then concat("Internacional» ",a.anpinternacional,
case when a.anpfederales <> "" then concat(" | Nacional» ",a.anpfederales,
case when a.anpotras <> "" then concat(" | ",a.anpotras) else '' end) else
case when a.anpotras <> "" then concat(" | ",a.anpotras) else '' end end ) else
case when a.anpfederales <> "" then concat("Nacional» ",a.anpfederales,
case when a.anpotras <> "" then concat(" | ",a.anpotras) else '' end) else
case when a.anpotras <> "" then a.anpotras else '' end end end)
else '' end as anp,
n.grupo as grupobio,
n.subgrupo as subgrupobio,
n.formadecrecimiento,
n.idnombrecatvalido,
n.idnombrecat,
ec.endemismo,
n.ambientenombre as ambiente,
case when e.validacionambientegeneral ='VALIDO' and ba.bufferporambiente like '%BUFFER%' then 'Válido con tolerancia'
when e.validacionambientegeneral ='VALIDO' and ba.bufferporambiente not like '%BUFFER%' then concat('Válido ',lower(ba.bufferporambiente))
when e.validacionambientegeneral ='NO VALIDO' then 'No válido'
else concat(upper(left(e.validacionambientegeneral, 1)), lower(substring(e.validacionambientegeneral, 2))) end as validacionambiente,
n.reinocat as reino,
n.divisionphylumcat as phylumdivision,
n.clasecat as clase,
n.ordencat as orden,
case when n.familiacat<>'' then n.familiacat when nol.familiaoriginallimpio not in ('NO DISPONIBLE','',"indet","indet.","auxiliar2","ns","ns1","undet.","unidentified","unknown") then nol.familiaoriginallimpio else '' end as familia,
case when n.generocat<>'' then n.generocat when nol.generooriginallimpio not in ('NO DISPONIBLE','',"indet","indet.","auxiliar2","ns","ns1","undet.","unidentified","unknown") then nol.generooriginallimpio else '' end as genero,

if(n.comentarioscat like '%Validado completamente%',n.nombrecatscat,if(n.comentarioscat like '%Falta validar taxón%',n.nombreoriginallimpioscat,'')) as especie,
case when e.calificadordeterminacioninfraespecieoriginal<>'' then e.calificadordeterminacioninfraespecieoriginal when e.calificadordeterminacionespecieoriginal<>'' then e.calificadordeterminacionespecieoriginal when e.calificadordeterminaciongenerooriginal<>'' then e.calificadordeterminaciongenerooriginal else '' end as calificadordeterminacion, 

case when (n.generocat<>'' or nol.generooriginallimpio not in ('NO DISPONIBLE','',"indet","indet.","auxiliar2","ns","ns1","undet.","unidentified","unknown")) and
(n.epitetoespecificocat not in ('NO DISPONIBLE','')  or nol.epitetoespecificooriginallimpio not in ('NO DISPONIBLE','',"indet","indet.","auxiliar2","ns","ns1","undet.","unidentified","unknown"))
then case when n.categoriainfraespeciecat<>'' then n.categoriainfraespeciecat when nol.categoriainfraespecieoriginal<>'' and nol.epitetoinfraespecificooriginallimpio not in ('NO DISPONIBLE','',"indet","indet.","auxiliar2","ns","ns1","undet.","unidentified","unknown") then nol.categoriainfraespecieoriginal else '' end else '' end as categoriainfraespecie,

case when (n.generocat<>'' or nol.generooriginallimpio not in ('NO DISPONIBLE','',"indet","indet.","auxiliar2","ns","ns1","undet.","unidentified","unknown")) and
(n.epitetoespecificocat not in ('NO DISPONIBLE','')  or nol.epitetoespecificooriginallimpio not in ('NO DISPONIBLE','',"indet","indet.","auxiliar2","ns","ns1","undet.","unidentified","unknown"))
then case when n.categoriainfraespecie2cat<>'' then n.categoriainfraespecie2cat when nol.categoriainfraespecieoriginal2<>'' and nol.epitetoinfraespecificooriginal2limpio not in ('NO DISPONIBLE','',"indet","indet.","auxiliar2","ns","ns1","undet.","unidentified","unknown")then nol.categoriainfraespecieoriginal2 else '' end else '' end as categoriainfraespecie2,
if(n.comentarioscat like '%Validado completamente%',n.autoridadcatscat,'') as autor,
if(n.comentarioscat like '%Validado completamente%',n.estatuscatscat,'') as estatustax,
er.referenciatax as reftax,
case when n.comentarioscat like "%completamente%" then 'SI' else 'NO' end as taxonvalidado,
n.reinocatvalido AS reinovalido,
n.divisionphylumcatvalido AS phylumdivisionvalido,
n.clasecatvalido AS clasevalida,
n.ordencatvalido AS ordenvalido,
n.familiacatvalido AS familiavalida,
n.generocatvalido as generovalido,

case when n.generocatvalido not in ('NO DISPONIBLE','') and n.epitetoespecificocatvalido not in ('NO DISPONIBLE','') then
trim(concat(n.generocatvalido,
case when n.subgenerocatvalido not in ('NO DISPONIBLE','') then concat(" (",n.subgenerocatvalido,")") else "" end,
case when n.epitetoinfraespecificocatvalido not in ('NO DISPONIBLE','') then concat(' ',
case when n.epitetoespecificocatvalido in ('NO DISPONIBLE','') then '' else n.epitetoespecificocatvalido end,' ',
case when n.epitetoinfraespecificocatvalido in ('NO DISPONIBLE','') then '' else n.epitetoinfraespecificocatvalido end,' ',n.epitetoinfraespecifico2catvalido)
else concat(' ', case when n.epitetoespecificocatvalido in ('NO DISPONIBLE','') then '' else n.epitetoespecificocatvalido end)end))
else '' end as especievalida,

case when n.categoriainfraespeciecatvalido<>'' then n.categoriainfraespeciecatvalido else '' end as categoriainfraespecievalida,

case when n.categoriainfraespecie2catvalido<>'' then n.categoriainfraespecie2catvalido else '' end as categoriainfraespecie2valida, /*campo nuevo en el geoportal *********************************************************/
case when n.generocatvalido not in ('NO DISPONIBLE','') and n.epitetoespecificocatvalido not in ('NO DISPONIBLE','') then
trim(concat(n.generocatvalido," ",n.epitetoespecificocatvalido)) else "" end as especievalidabusqueda,

case when n.epitetoinfraespecifico2catvalido <>'' then n.autoranioinfraespecie2catvalido 
when n.epitetoinfraespecificocatvalido <>'' then n.autoranioinfraespeciecatvalido when n.epitetoespecificocatvalido <>'' then n.autoranioespeciecatvalido
when n.subgenerocatvalido <>'' then n.autoraniosubgenerocatvalido when n.generocatvalido <>'' then n.autoraniogenerocatvalido
when n.tribucatvalido <>'' then ''
when n.subfamiliacatvalido <>'' then ''
when n.familiacatvalido <>'' then n.autoraniofamiliacatvalido 
when n.subordencatvalido <>'' then ''
when n.ordencatvalido <>'' then n.autoranioordencatvalido else '' end as autorvalido,

case when n.epitetoinfraespecifico2catvalido <>'' then n.catdiccinfraespecie2catvalido
when n.epitetoinfraespecificocatvalido <>'' then n.catdiccinfraespeciecatvalido when n.epitetoespecificocatvalido <>'' then n.catdiccespeciecatvalido
when n.subgenerocatvalido <>'' then n.sistemaclasificacionsubgenerocatvalido 
when n.generocatvalido <>'' then n.sistemaclasificaciongenerocatvalido 
when n.tribucatvalido <>'' then n.sistemaclasificaciontribucatvalido
when n.subfamiliacatvalido <>'' then n.sistemaclasificaciontribucatvalido
when n.familiacatvalido <>'' then n.sistemaclasificacionfamiliacatvalido 
when n.subordencatvalido <>'' then n.sistemaclasificacionsubordencatvalido
when n.ordencatvalido <>'' then n.sistemaclasificacionordencatvalido 
when n.clasecatvalido <>'' then n.sistemaclasificacionclasecatvalido
when n.divisionphylumcatvalido <>'' then n.sistemaclasificaciondivisionphylumcatvalido
when n.reinocatvalido <>'' then n.sistemaclasificacionreinocatvalido  else '' end as reftaxvalido,
n.categoriavalidocatscat,
n.nombrevalidocatscat,
n.taxonextinto,
if(e.procedenciadatos='FossilSpecimen','SI','') as ejemplarfosil,
ec.nombrecomun,
ec.categoriaresidenciaaves,
ec.prioritaria,
ec.nivelprioridad,
ec.exoticainvasora,
ec.nom059,
ec.cites,
ec.iucn,
ec.coleccion,
ec.institucion,
ec.paiscoleccion,
e.numerocatalogo as numcatalogo,
e.numerocolecta as numcolecta,
e.procedenciadatos as procedenciaejemplar,
case when ad.persona not in('NO APLICA','NO DISPONIBLE','NO PROPORCIONADO','') then ad.persona else nd.persona end as determinador,
case when e.aniodeterminacion not in (9999,-1) then concat(e.aniodeterminacion,
case when e.mesdeterminacion not between 1 and 12 or e.mesdeterminacion = 99 then '' else
concat('-',case when e.mesdeterminacion < 10 then concat('0',e.mesdeterminacion) else e.mesdeterminacion end,
case when e.diadeterminacion not between 1 and 31 then '' else concat('-',
case when e.diadeterminacion < 10 then concat('0',e.diadeterminacion) else e.diadeterminacion end) end) end) else '' end as fechadeterminacion,
if(e.diadeterminacion in(99,-1),null,e.diadeterminacion) as diadeterminacion,
if(e.mesdeterminacion in(99,-1),null,e.mesdeterminacion) as mesdeterminacion,
if(e.aniodeterminacion=9999,null,e.aniodeterminacion) as aniodeterminacion,
case when ac.persona not in('NO APLICA','NO DISPONIBLE','NO PROPORCIONADO','') then ac.persona else nc.persona end as colector,
case when e.aniocolecta not in (9999,-1) then concat(e.aniocolecta,
case when e.mescolecta not between 1 and 12 or e.mescolecta = 99 then '' else
concat('-',case when e.mescolecta < 10 then concat('0',e.mescolecta) else e.mescolecta end,
case when e.diacolecta not between 1 and 31 then '' else concat('-',
case when e.diacolecta < 10 then concat('0',e.diacolecta) else e.diacolecta end) end) end) else '' end as fechacolecta,
if(e.diacolecta in(99,-1),null,e.diacolecta) as diacolecta,
if(e.mescolecta in(99,-1),null,e.mescolecta) as mescolecta,
if(e.aniocolecta=9999,null,e.aniocolecta) as aniocolecta,
t.tipo,
e.observacionusoinformacion as obsusoinfo,
e.probablelocnodecampo,
z.zonamapa,
r.paiscodigovalidacion as paiscodvalidacion,
r.estadocodigovalidacion as edocodvalidacion,
r.municipiocodigovalidacion as mpiocodvalidacion,
r.localidadcodigovalidacion as localidadcodvalidacion,
e.cuarentena,
pr.proyecto,
pr.clavebasedatos,
pr.identificacionarchivo,
pr.fuenteoriginal,
e.urlejemplar,
e.urlorigen,
e.licenciauso,
re.tiporestriccion,
n.comentarioscat,
n.comentarioscatvalido,
n.homonimosgenero,
n.homonimosespecie,
n.homonimosinfraespecie,
n.homonimosgenerocatvalido,
n.homonimosespeciecatvalido,
n.homonimosinfraespeciecatvalido,
n.distribucionnom2010,
r.idmias,
rmm.regionmarinamapa,
rgm.nombrerasgogeograficomapa,
rgm.tiporasgogeograficomapa,
m.mt24mapa,
vpi.noaplicavegetacionmapa,
r.distmpio,
r.codificacion,
p.procesovalidacion,
e.estadoregistro,
pr.fuentegrafico,
pr.formadecitar,
pr.urlproyectoconabio,
if(n.comentarioscat like '%Validado completamente%',n.categoriacatscat,if(n.comentarioscat like '%Falta validar taxón%',n.categoriaoriginalscat,'')) as categoriataxonomica,
if(ig.llaveejemplar is null,false,if(n.grupo not in('virus','NO DISPONIBLE','Bacterias'),true,false)) as geoportal
case when e.ultimafechaactualizacion>=n.ultimafechaactualizacion then
case when e.ultimafechaactualizacion>=r.ultimafechaactualizacion then e.ultimafechaactualizacion else r.ultimafechaactualizacion end else
case when n.ultimafechaactualizacion>=r.ultimafechaactualizacion then n.ultimafechaactualizacion else r.ultimafechaactualizacion end end as ultimafechaactualizacion,
e.version as version,
ro.paisoriginal,
ro.estadooriginal,
ro.municipiooriginal,
'' as llavecontrolcambios
from snib.ejemplar_curatorial e inner join snib.proyecto pr on e.llaveproyecto=pr.llaveproyecto
inner join snib.localidad l on e.idlocalidad=l.idlocalidad
inner join snib.bufferporambiente ba on e.idbufferporambiente=ba.idbufferporambiente
inner join snib.persona nd on e.idnombredeterminador=nd.idpersona
inner join snib.persona ad on e.idabreviadodeterminador=ad.idpersona
inner join snib.persona nc on e.idnombrecolector=nc.idpersona
inner join snib.persona ac on e.idabreviadocolector=ac.idpersona
inner join snib.tipo t on e.idtipo=t.idtipo
inner join snib.conabiogeografia r on e.llaveregionsitiosig = r.llaveregionsitiosig
inner join geoportal_trabajo.anps a on r.llaveregionsitiosig=a.llaveregionsitiosig
inner join snib.regionmarinamapa rmm on r.idregionmarinamapa=rmm.idregionmarinamapa
inner join snib.rasgogeograficomapa rgm on r.idrasgogeograficomapa=rgm.idrasgogeograficomapa
inner join snib.vegetacionprimariainegi vpi on r.idvegetacionprimariainegi=vpi.idvegetacionprimariainegi
inner join snib.regionmapa rm on r.idregionmapa=rm.idregionmapa
inner join snib.zonamapa z on r.idzonamapa=z.idzonamapa
inner join snib.procesovalidacion p on r.idprocesovalidacion=p.idprocesovalidacion
inner join snib.mt24mapa m on r.idmt24mapa=m.idmt24mapa
inner join snib.vegetacionserenanalcms vs on r.idvegetacionserenanalcms=vs.idvegetacionserenanalcms
inner join snib.geografiaoriginal go on e.llavesitio=go.llavesitio
inner join snib.regionoriginal ro on go.idregionoriginal=ro.idregionoriginal
inner join geoportal_trabajo.EjemplarVegetacionINEGI ev on e.llaveejemplar = ev.llaveejemplar
inner join geoportal_trabajo.nombre1 n on e.llavenombre = n.llavenombre
inner join snib.nombreoriginallimpio nol on e.llavenombre=nol.llavenombre
inner join snib.restriccionejemplar re on e.idrestriccionejemplar = re.idrestriccionejemplar
inner join geoportal_trabajo.EjemplarColeccionNomComun ec on e.llaveejemplar=ec.llaveejemplar
inner join geoportal_trabajo.ejemplar_referenciatax er on e.llaveejemplar=er.llaveejemplar
left join geoportal_trabajo.InformacionGeoportal ig on e.llaveejemplar=ig.llaveejemplar
where e.estadoregistro='';

-- Estas lineas se cambiaron de lugar para evitar regeneración de indices.

CALL snib.23_BuscaCaracteresControlyComillas_tabla("snib","informaciongeoportal_siya");

CALL geoportal_trabajo.revisatabla_buscacomillas;

ALTER TABLE snib.informaciongeoportal_siya
ADD PRIMARY KEY (`idejemplar`),
ADD KEY `idx_coleccion` (`coleccion`),
ADD KEY `idx_institucion` (`institucion`),
ADD KEY `idx_idnombrecatvalido` (`idnombrecatvalido`),
ADD KEY `idx_municipiomapa` (`municipiomapa`),
ADD KEY `idx_usvserieVI` (`usvserieVI`),
ADD KEY `idx_paismapa` (`paismapa`),
ADD KEY `idx_estadomapa` (`estadomapa`),
ADD KEY `idx_grupobio` (`grupobio`),
ADD KEY `idx_especievalidabusqueda` (`especievalidabusqueda`),
ADD KEY `idx_nom059` (`nom059`(255)),
ADD KEY `idx_cites` (`cites`(255)),
ADD KEY `idx_iucn` (`iucn`(255)),
ADD KEY `idx_prioritaria` (`prioritaria`),
ADD KEY `idx_exoticainvasora` (`exoticainvasora`),
ADD KEY `idx_geovalidacion` (`geovalidacion`),
ADD KEY `idx_anp` (`anp`),
ADD KEY `idx_reino` (`reino`),
ADD KEY `idx_phylumdivision` (`phylumdivision`),
ADD KEY `idx_clase` (`clase`),
ADD KEY `idx_orden` (`orden`),
ADD KEY `idx_familia` (`familia`),
ADD KEY `idx_genero` (`genero`),
ADD KEY `idx_reinovalido` (`reinovalido`),
ADD KEY `idx_phylumdivisionvalido` (`phylumdivisionvalido`),
ADD KEY `idx_clasevalida` (`clasevalida`),
ADD KEY `idx_ordenvalido` (`ordenvalido`),
ADD KEY `idx_familiavalida` (`familiavalida`),
ADD KEY `idx_generovalido` (`generovalido`),
ADD KEY `idx_geoportal` (`geoportal`),
ADD KEY `idx_idmias` (`idmias`),
ADD KEY `idx_regionmarinamapa` (`regionmarinamapa`),
ADD KEY `idx_categoriaresidenciaaves` (`categoriaresidenciaaves`),
ADD KEY `idx_especie` (`especie`);

update snib.informaciongeoportal_siya
set geovalidacion=replace(geovalidacion,'95ig','1995ig')
where geovalidacion like '%95ig%';

-- Modificamos campos especie, autor, estatustax, y categoriatax para atender lo indicado al final en el JIRA4721

update snib.informaciongeoportal_siya
set especie='',
autor='',
estatustax=''
where especie not like '% %' or (especie like '% %' and categoriataxonomica in('familia','orden'));

update snib.informaciongeoportal_siya
set categoriataxonomica=''
where especie='';

/* Llenamos el campo referenciatax con indicaciones del JIRA 4721,
 parece es mejor idea poner en el inner join la tabla ya que el update tardo más de 7 horas

update geoportal_trabajo.ejemplar_referenciatax er inner join snib.informaciongeoportal_siya e on er.llaveejemplar=e.idejemplar
set e.reftax=er.referenciatax;

 Modificamos lo solicitado en el JIRA 4321 para modificar el campo geovalidacion */

/*update snib.informaciongeoportal_siya i inner join snib.ejemplar_curatorial e on i.idejemplar=e.llaveejemplar
inner join snib.conabiogeografia c on e.llaveregionsitiosig=c.llaveregionsitiosig
set i.geovalidacion=concat(i.geovalidacion,'. No válido localidad')
where c.validacionlocalidad='NO VALIDO';*/

create temporary table geoportal_trabajo.ej_novalidolocalidad
select llaveejemplar
from snib.ejemplar_curatorial e inner join snib.conabiogeografia c on e.llaveregionsitiosig=c.llaveregionsitiosig
where c.validacionlocalidad='NO VALIDO';

alter table geoportal_trabajo.ej_novalidolocalidad add primary key(llaveejemplar);

update geoportal_trabajo.ej_novalidolocalidad ej inner join snib.informaciongeoportal_siya i on ej.llaveejemplar=i.idejemplar
set i.geovalidacion=concat(i.geovalidacion,'. No válido localidad');

drop table geoportal_trabajo.ej_novalidolocalidad;

/* Se modifican los datos de coleccion e institucion en la tabla final */

update snib.informaciongeoportal_siya
set coleccion = replace(coleccion,"NO APLICA ","")
where coleccion like "NO APLICA %" and coleccion <> "NO APLICA NO APLICA";

update snib.informaciongeoportal_siya
set coleccion = replace(coleccion,"NO DISPONIBLE ","")
where coleccion like "NO DISPONIBLE %" and coleccion not in("NO DISPONIBLE NO PROPORCIONADO","NO DISPONIBLE NO DISPONIBLE");

update snib.informaciongeoportal_siya
set coleccion = replace(coleccion," NO APLICA","")
where coleccion like "% NO APLICA%" and coleccion <> "NO APLICA NO APLICA";

update snib.informaciongeoportal_siya
set coleccion = replace(coleccion," NO DISPONIBLE","")
where coleccion like "% NO DISPONIBLE" and coleccion not in("INF NO DISPONIBLE","NO DISPONIBLE NO DISPONIBLE");

update snib.informaciongeoportal_siya
set institucion = "Colección Particular"
where institucion = "NO APLICA (NO APLICA) Colección Particular";

update snib.informaciongeoportal_siya
set institucion = replace(institucion,"NO APLICA ","")
where institucion like "NO APLICA %" and institucion<>"NO APLICA NO APLICA";

update snib.informaciongeoportal_siya
set institucion = replace(institucion,"NO DISPONIBLE ","")
where institucion like "NO DISPONIBLE %" and institucion not in("NO DISPONIBLE NO PROPORCIONADO","NO DISPONIBLE NO DISPONIBLE");

update snib.informaciongeoportal_siya
set institucion = replace(institucion," NO APLICA","")
where institucion like "% NO APLICA" and institucion <> "NO APLICA NO APLICA";

update snib.informaciongeoportal_siya
set institucion = replace(institucion," NO DISPONIBLE","")
where institucion like "% NO DISPONIBLE" and institucion not in("INF NO DISPONIBLE","NO DISPONIBLE NO DISPONIBLE");

update snib.informaciongeoportal_siya
set coleccion = "NO APLICA"
where coleccion = "NO APLICA NO APLICA";

update snib.informaciongeoportal_siya
set coleccion = "NO DISPONIBLE"
where coleccion IN("INF NO DISPONIBLE","NO DISPONIBLE NO PROPORCIONADO","NO DISPONIBLE NO DISPONIBLE");

update snib.informaciongeoportal_siya
set institucion = "NO APLICA"
where institucion = "NO APLICA NO APLICA";

update snib.informaciongeoportal_siya
set institucion = "NO DISPONIBLE"
where institucion IN("NO DISPONIBLE NO PROPORCIONADO","NO DISPONIBLE NO DISPONIBLE");

/*update snib.informaciongeoportal_siya
set geoportal=false;*/

-- Agregado el 19/04/2021 qrys para eliminar NA, ND, NO APLICA, NO DISPONIBLE
update snib.informaciongeoportal_siya
set tipo=''
where tipo in ('NO APLICA','NO DISPONIBLE');

update snib.informaciongeoportal_siya
set localidad=''
where localidad in  ('ND..','nd2','NO DATA','no data available','No data Available.','NO APLICA','NO DISPONIBLE','NO PROPORCIONADO','ND','NA','NP');

update snib.informaciongeoportal_siya
set ambiente=''
where ambiente in ('ND','NO DISPONIBLE');

update snib.informaciongeoportal_siya
set subgrupobio=''
where subgrupobio in ('NO ASIGNADO','NO DISPONIBLE');

update snib.informaciongeoportal_siya
set categoriainfraespecie=''
where categoriainfraespecie ='NO DISPONIBLE';

update snib.informaciongeoportal_siya
set autor=''
where autor in ('NO APLICA','NO DISPONIBLE','NO PROPORCIONADO','ND','NA','NP');

update snib.informaciongeoportal_siya
set reftax=''
where reftax in ('NO APLICA','NO DISPONIBLE','NO PROPORCIONADO','ND','NA','NP');

update snib.informaciongeoportal_siya
set autorvalido=''
where autorvalido in ('NO APLICA','NO DISPONIBLE','NO PROPORCIONADO','ND','NA','NP');

update snib.informaciongeoportal_siya
set colector=''
where colector in ('NO APLICA','NO DISPONIBLE','NO PROPORCIONADO','ND','NA','NP');

update snib.informaciongeoportal_siya
set determinador=''
where determinador in ('NO APLICA','NO DISPONIBLE','NO PROPORCIONADO','ND','NA','NP');

update snib.informaciongeoportal_siya
set categoriainfraespecie2=''
where categoriainfraespecie2 in ('NO APLICA','NO DISPONIBLE','NO PROPORCIONADO','ND','NA','NP');

/* Obtenemos a partir de la tabla _TransformaTablaNombre de la bd catalogocentralizado y el campo idnombrecatvalido el valor del campo categoriataxonomica.
update snib.informaciongeoportal_siya i inner join catalogocentralizado._TransformaTablaNombre t on i.idnombrecatvalido = t.IdCAT
set i.categoriataxonomica=t.UltimaCategoriaTaxonomica;*/


/*Esta consulta se liga con la ultima tabla del geoportal, se exlcuyen los virus, por lo que es importante asegurse de que dicho grupo seguira sin aparecer en el geoprotal
NOTA: Preguntar antes de ejecutar este qry*/

/* 2025-02-05 Tuvimos que crear una tabla con puras llaves ejemplar porque el qry anterior no pelaba lo indeces  y Protozoa si se va al geoportal

update snib.informaciongeoportal_siya i inner join geoportal_trabajo.InformacionGeoportal g on i.idejemplar=g.llaveejemplar
set i.geoportal=true
where grupobio not in('virus','NO DISPONIBLE','Bacterias','Protozoa'); 

create temporary table geoportal_trabajo.ig_idejemplar
select llaveeejemplar as idejemplar
from geoportal_trabajo.InformacionGeoportal;

alter table geoportal_trabajo.ig_idejemplar add primary key(idejemplar);

update snib.informaciongeoportal_siya i inner join geoportal_trabajo.ig_idejemplar g using(idejemplar)
set i.geoportal=true
where grupobio not in('virus','NO DISPONIBLE','Bacterias'); */


/*

-- generamos el campo llavecontrolcambios para revisar si hay cambios respecto a la versión anterior.

update snib.informaciongeoportal_siya
set llavecontrolcambios=MD5(CONCAT(region,localidad,if(longitud is null,'',longitud),if(latitud is null,'',latitud),datum,geovalidacion,paismapa,if(idestadomapa is null,'',idestadomapa),claveestadomapa,estadomapa,if(mt24idestadomapa is null,'',mt24idestadomapa),mt24claveestadomapa,mt24nombreestadomapa,if(idmunicipiomapa is null,'',idmunicipiomapa),clavemunicipiomapa,municipiomapa,if(mt24idmunicipiomapa is null,'',mt24idmunicipiomapa),mt24clavemunicipiomapa,mt24nombremunicipiomapa,if(incertidumbreXY is null,'',incertidumbreXY),if(altitudmapa is null,'',altitudmapa),usvserieI,usvserieII,usvserieIII,usvserieIV,usvserieV,usvserieVI,usvserieVII,usvINEGI,vegetacionserenanalcms,if(idanpfederal1 is null,'',idanpfederal1),if(idanpfederal2 is null,'',idanpfederal2),anp,grupobio,subgrupobio,formadecrecimiento,idnombrecatvalido,idnombrecat,endemismo,ambiente,validacionambiente,reino,phylumdivision,clase,orden,familia,genero,especie,calificadordeterminacion,categoriainfraespecie,categoriainfraespecie2,autor,estatustax,reftax,taxonvalidado,reinovalido,phylumdivisionvalido,clasevalida,ordenvalido,familiavalida,generovalido,especievalida,categoriainfraespecievalida,categoriainfraespecie2valida,especievalidabusqueda,autorvalido,reftaxvalido,categoriavalidocatscat,nombrevalidocatscat,taxonextinto,ejemplarfosil,nombrecomun,categoriaresidenciaaves,prioritaria,nivelprioridad,exoticainvasora,nom059,cites,iucn,coleccion,institucion,paiscoleccion,numcatalogo,numcolecta,procedenciaejemplar,determinador,fechadeterminacion,if(diadeterminacion is null,'',diadeterminacion),if(mesdeterminacion is null,'',mesdeterminacion),if(aniodeterminacion is null,'',aniodeterminacion),colector,fechacolecta,if(diacolecta is null,'',diacolecta),if(mescolecta is null,'',mescolecta),if(aniocolecta is null,'',aniocolecta),tipo,obsusoinfo,probablelocnodecampo,zonamapa,if(paiscodvalidacion is null,'',paiscodvalidacion),if(localidadcodvalidacion is null,'',localidadcodvalidacion),if(edocodvalidacion is null,'',edocodvalidacion),if(mpiocodvalidacion is null,'',mpiocodvalidacion),proyecto,clavebasedatos,identificacionarchivo,fuenteoriginal,urlejemplar,urlorigen,licenciauso,tiporestriccion,comentarioscat,comentarioscatvalido,homonimosgenero,homonimosespecie,homonimosinfraespecie,homonimosgenerocatvalido,homonimosespeciecatvalido,homonimosinfraespeciecatvalido,distribucionnom2010,idmias,regionmarinamapa,nombrerasgogeograficomapa,tiporasgogeograficomapa,mt24mapa,noaplicavegetacionmapa,if(distmpio is null,'',distmpio),if(codificacion is null,'',codificacion),procesovalidacion,estadoregistro,fuente,formadecitar,urlproyecto,categoriataxonomica,geoportal));

-- Agregamos al histórico de cambios los registros con cambio en algún campo.

insert into dwh.H_informaciongeoportal_siya(idejemplar,region,localidad,longitud,latitud,datum,geovalidacion,paismapa,idestadomapa,claveestadomapa,estadomapa,mt24idestadomapa,mt24claveestadomapa,mt24nombreestadomapa,idmunicipiomapa,clavemunicipiomapa,municipiomapa,mt24idmunicipiomapa,mt24clavemunicipiomapa,mt24nombremunicipiomapa,incertidumbreXY,altitudmapa,usvserieI,usvserieII,usvserieIII,usvserieIV,usvserieV,usvserieVI,usvserieVII,usvINEGI,vegetacionserenanalcms,idanpfederal1,idanpfederal2,anp,grupobio,subgrupobio,formadecrecimiento,idnombrecatvalido,idnombrecat,endemismo,ambiente,validacionambiente,reino,phylumdivision,clase,orden,familia,genero,especie,calificadordeterminacion,categoriainfraespecie,categoriainfraespecie2,autor,estatustax,reftax,taxonvalidado,reinovalido,phylumdivisionvalido,clasevalida,ordenvalido,familiavalida,generovalido,especievalida,categoriainfraespecievalida,categoriainfraespecie2valida,especievalidabusqueda,autorvalido,reftaxvalido,categoriavalidocatscat,nombrevalidocatscattaxonextinto,ejemplarfosil,nombrecomun,categoriaresidenciaaves,prioritaria,nivelprioridad,exoticainvasora,nom059,cites,iucn,coleccion,institucion,paiscoleccion,numcatalogo,numcolecta,procedenciaejemplar,determinador,fechadeterminacion,diadeterminacion,mesdeterminacion,aniodeterminacion,colector,fechacolecta,diacolecta,mescolecta,aniocolecta,tipo,obsusoinfo,probablelocnodecampo,zonamapa,paiscodvalidacion,localidadcodvalidacion,edocodvalidacion,mpiocodvalidacion,cuarentena,proyecto,clavebasedatos,identificacionarchivo,fuenteoriginal,urlejemplar,urlorigen,licenciauso,tiporestriccion,comentarioscat,comentarioscatvalido,homonimosgenero,homonimosespecie,homonimosinfraespecie,homonimosgenerocatvalido,homonimosespeciecatvalido,homonimosinfraespeciecatvalido,distribucionnom2010,idmias,regionmarinamapa,nombrerasgogeograficomapa,tiporasgogeograficomapa,mt24mapa,noaplicavegetacionmapa,distmpio,codificacion,procesovalidacion,estadoregistro,fuente,formadecitar,urlproyecto,categoriataxonomica,geoportal,ultimafechaactualizacion,version,llavecontrolcambios)
select ih.idejemplar,ih.region,ih.localidad,ih.longitud,ih.latitud,ih.datum,ih.geovalidacion,ih.paismapa,ih.idestadomapa,ih.claveestadomapa,ih.estadomapa,ih.mt24idestadomapa,ih.mt24claveestadomapa,ih.mt24nombreestadomapa,ih.idmunicipiomapa,ih.clavemunicipiomapa,ih.municipiomapa,ih.mt24idmunicipiomapa,ih.mt24clavemunicipiomapa,ih.mt24nombremunicipiomapa,ih.incertidumbreXY,ih.altitudmapa,ih.usvserieI,ih.usvserieII,ih.usvserieIII,ih.usvserieIV,ih.usvserieV,ih.usvserieVI,ih.usvserieVII,ih.usvINEGI,ih.vegetacionserenanalcms,ih.idanpfederal1,ih.idanpfederal2,ih.anp,ih.grupobio,ih.subgrupobio,ih.formadecrecimiento,ih.idnombrecatvalido,ih.idnombrecat,ih.endemismo,ih.ambiente,ih.validacionambiente,ih.reino,ih.phylumdivision,ih.clase,ih.orden,ih.familia,ih.genero,ih.especie,ih.calificadordeterminacion,ih.categoriainfraespecie,ih.categoriainfraespecie2,ih.autor,ih.estatustax,ih.reftax,ih.taxonvalidado,ih.reinovalido,ih.phylumdivisionvalido,ih.clasevalida,ih.ordenvalido,ih.familiavalida,ih.generovalido,ih.especievalida,ih.categoriainfraespecievalida,ih.categoriainfraespecie2valida,ih.especievalidabusqueda,ih.autorvalido,ih.reftaxvalido,ih.categoriavalidocatscat,ih.nombrevalidocatscat,ih.taxonextinto,ih.ejemplarfosil,ih.nombrecomun,ih.categoriaresidenciaaves,ih.prioritaria,ih.nivelprioridad,ih.exoticainvasora,ih.nom059,ih.cites,ih.iucn,ih.coleccion,ih.institucion,ih.paiscoleccion,ih.numcatalogo,ih.numcolecta,ih.procedenciaejemplar,ih.determinador,ih.fechadeterminacion,ih.diadeterminacion,ih.mesdeterminacion,ih.aniodeterminacion,ih.colector,ih.fechacolecta,ih.diacolecta,ih.mescolecta,ih.aniocolecta,ih.tipo,ih.obsusoinfo,ih.probablelocnodecampo,ih.zonamapa,ih.paiscodvalidacion,ih.localidadcodvalidacion,ih.edocodvalidacion,ih.mpiocodvalidacion,ih.cuarentena,ih.proyecto,ih.clavebasedatos,ih.identificacionarchivo,ih.fuenteoriginal,ih.urlejemplar,ih.urlorigen,ih.licenciauso,ih.tiporestriccion,ih.comentarioscat,ih.comentarioscatvalido,ih.homonimosgenero,ih.homonimosespecie,ih.homonimosinfraespecie,ih.homonimosgenerocatvalido,ih.homonimosespeciecatvalido,ih.homonimosinfraespeciecatvalido,ih.distribucionnom2010,ih.idmias,ih.regionmarinamapa,ih.nombrerasgogeograficomapa,ih.tiporasgogeograficomapa,ih.mt24mapa,ih.noaplicavegetacionmapa,ih.distmpio,ih.codificacion,ih.procesovalidacion,ih.estadoregistro,ih.fuente,ih.formadecitar,ih.urlproyecto,ih.categoriataxonomica,ih.geoportal,ih.ultimafechaactualizacion,ih.version,ih.llavecontrolcambios
from snib.informaciongeoportal_siyahistorico ih inner join snib.informaciongeoportal_siya i on ih.idejemplar=i.idejemplar
where ih.llavecontrolcambios<>i.llavecontrolcambios;

-- Agregar los registros nuevos registros que estan en infromaciongeopoprtal_siya pero no en informaciongeoportal_siyahistorico

insert into dwh.H_informaciongeoportal_siya_regnuevos(idejemplar)
select i.idejemplar from snib.informaciongeoportal_siya i left join snib.informaciongeoportal_siyahistorico ih on i.idejemplar=ih.idejemplar
where ih.idejemplar is null;

-- drop table if exists snib.informaciongeoportal_siyahistorico; */

SELECT 'Termino';
END $$

DELIMITER ;