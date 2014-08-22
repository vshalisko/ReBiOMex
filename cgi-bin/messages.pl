use utf8;
# this subprogram determines messages that should be used elsewhere for output

{
  # $language variable is persistent between calls and defines interface language, 
  # Note: it will be necessary to develop some mechanism to determine this variable depending on context, or may be some CGI variable,
  # getting it from some subprogram
  my $language = 'sp';
  # %mess_db hash is persistent between calls of sub message and contains declarations for all messages
  # there is some internal structure of numeration, all error messages start with 1XXX, all interface 
  # messages  start with 2XXX, content-related strings start with 8XXX, page titles start with 9XXX
  # messages  start with RXXX, access paths (should be repeated for each language set)
  
  my %mess_db = (
    R_L => { # parameters for Linux/Unix based systems (production)
      R002 => '/images/', # full-size image path on web-server
      R003 => '/images_lores/', # reduced image path on web-server
      R004 => '/images_thumb/', # thumb image path on web-server      
      R005 => '/home2/rebiomex/www/images/', # full image path disc in unix e.g. /var/www/ibug/htdocs/ should appear as \\var\\www\\ibug\\htdocs\\
      R006 => '/home2/rebiomex/www/images_lores/', # reduced image path disc in unix
      R007 => '/home2/rebiomex/www/images_thumb/', # thumb image path disc in unix
      R008 => '', # drive where DB acces control files are located (windows only, in linyx empty) 
      R009 => '/home2/rebiomex/rebiomex_database_access/', # path where DB acces control files are located 
    },
    R_W => { # parameters for windows systems (developers)
      R002 => '/ibug/images/', # full-size image path on web-server
      R003 => '/ibug/images_lores/', # reduced image path on web-server
      R004 => '/ibug/images_thumb/', # thumb image path on web-server      
      R005 => 'c:\\IBUG\\www\\ibug_database\\images\\', # full image path disc in windows
      R006 => 'c:\\IBUG\\www\\ibug_database\\images_lores\\', # reduced image path disc in windows
      R007 => 'c:\\IBUG\\www\\ibug_database\\images_thumb\\', # thumb image path disc in windows
      R008 => 'c:', # drive where DB acces control files are located (windows only, in linyx empty) 
      R009 => '/IBUG/ibug_database_access/', # path where DB acces control files are located 

    },

    sp => {
      0001 => 'Prueba soporte de idioma Español', # test
    
      # system error messages
      1001 => 'Conexión con base de datos es imposible o fue perdida',
      1002 => 'Se ha producido un error durante cambio de directorio de trabajo',
      1003 => 'Se ha producido un error durante conexión con base de datos',
      1004 => 'Se ha producido un error durante la preparación del codigo SQL SET VARIABLES ...',
      1005 => 'Se ha producido un error durante la ejecución del codigo SQL SET VARIABLES ...',
      1006 => 'Se ha producido un error durante la terminación del codigo SQL SET VARIABLES ...',
      1007 => 'Se ha producido un error durante desconexión de base de datos',
      1008 => 'codigo de error',
      1009 => 'Se ha producido un error durante la preparación de consulta SQL SELECT',
      1010 => 'Se ha producido un error durante la ejecución de consulta SQL SELECT',
      1011 => 'Se ha producido un error durante la terminación de consulta SQL SELECT',
      1012 => 'Se ha producido un error durante la preparación de subconsulta SQL SELECT',
      1013 => 'Se ha producido un error durante la ejecución de subconsulta SQL SELECT',
      1014 => 'Se ha producido un error durante la terminación de subconsulta SQL SELECT',
      1015 => 'Se ha producido un error durante la preparación de subconsulta SQL para identificación del usuario',
      1016 => 'Se ha producido un error durante la ejecución de subconsulta SQL para identificación del usuario',
      1017 => 'Se ha producido un error durante la terminación de subconsulta SQL para identificación del usuario',
      1018 => 'Se ha producido un error durante la preparación del codigo SQL definido por usuario',
      1019 => 'Se ha producido un error durante la ejecución del codigo SQL definido por usuario',
      1020 => 'Se ha producido un error durante la terminación del codigo SQL definido por usuario',
      1021 => 'Se ha producido un error durante la preparación de sentencia SQL UPDATE',
      1022 => 'Se ha producido un error durante la ejecución de sentencia SQL UPDATE',
      1023 => 'Se ha producido un error durante la terminación de sentencia SQL UPDATE',
      1024 => 'Se ha producido un error durante la preparación de sentencia SQL INSERT',
      1025 => 'Se ha producido un error durante la ejecución de sentencia SQL INSERT',
      1026 => 'Se ha producido un error durante la terminación de sentencia SQL INSERT',     
      1027 => 'Se ha producido un error durante la preparación de sentencia SQL DELETE',
      1028 => 'Se ha producido un error durante la ejecución de sentencia SQL DELETE',
      1029 => 'Se ha producido un error durante la terminación de sentencia SQL DELETE', 
      1030 => 'Muy extraño, mas que un registro fue encontrado, hay problema con datos',  
      1031 => 'Lista de parametros incompleta para realizar una consulta', # in ajax.cgi to ay that reference table was not defined
      1032 => 'No existen registros buscados', # in ajax.cgi to say that parametros de busqueda fueron vacios
      1033 => '', # not used, just to copy

      # user error messages
      2001 => 'Campo no puede contener numeros', # check_text sub message
      2002 => 'Campo puede contener solo numeros',  # check_numbe sub message
      2003 => 'Campo de fecha tiene que ser formateado como AAAA-MM-DD donde A son digitos del año, M son digitos del mes y D son digitos del dia',
      2004 => 'Campo obligatorio vacio',
      2005 => 'Problema con formato de datos',
      2006 => 'Campo puede contener solo numeros, signos &quot;-&quot; y &quot;.&quot;', 
      2007 => 'Campo puede contener solo letras sin cimbolos diacríticos, numeros, signos &quot;-&quot; y &quot;_&quot;',
      
      # lookup field names (to explain lookup parameters)
      3001 => 'texto buscado (nombre científico, nombre común, familia)',
      3002 => 'genero',
      3003 => 'especie',
      3004 => 'familia',
      3005 => 'municipio',
      3006 => 'estado',
      3007 => 'nombre de colector',
      3008 => 'numero de colecta',
      3009 => 'fecha de colecta',
      3010 => 'estatus de tipo',
      3011 => 'herbarium',
      3012 => 'nombre común',
      3013 => 'referencia de descripción/identificación de taxon',
      3014 => 'segmento de datos',
      3015 => 'buscar solo taxa con estatus',
      3016 => 'considerar solo identificación preferida',
      3017 => 'buscar solo especimenes incorporados a colección cientifica',
      
      # labels
      8001 => 'Genero indefinido', # list and info
      8002 => 'Familia incierta', # list and info
      8003 => 'sp.', # list and info
      8004 => 'Determinador sin especificar', # list and info
      8005 => 'Det.', # list and info
      8006 => 'Sin colector', # list and info  
      8007 => 's. n.', # list and info
      8008 => 'Col.', # list and info
      8009 => 'Sin identificación', # label
      8010 => 'msnm', # label
      8011 => 'HERBARIO', # label
      8012 => 'No.', # label
      8013 => 'de', # label
      8014 => 'Planta', # label
      8015 => 'IdEjemplar', # label
      8016 => 'Nombre común', # label
      8017 => 'Estado', # label
      8018 => 'Municipio', # label
      8019 => 'Localidad', # label
      8020 => 'Lat./Lon.', # label
      8021 => 'Alt.', # label
      8022 => 'Vegetación', # label
      8023 => 'Fecha', # label
      8024 => 'Notas', # label
      8025 => 'Col.', # label
      8026 => 'Det.', # label
      8027 => 'Plantas de', # label
      8028 => 'ReBiOMex - http://rebiomex.org', # label

      # page header titles
      9001 => 'ReBiOMex: acerca del sistema', # title for "about" page
      9002 => 'ReBiOMex: logout', # title for "login-logot" page
      9003 => 'ReBiOMex: login', # title for "login-logot" page
      9004 => 'ReBiOMex: login completado', # title for "login-logot" page
      9005 => 'ReBiOMex: exportación de datos XML', # title for "XML export page" page
      9006 => 'ReBiOMex: registro',
      9007 => 'ReBiOMex: consulta por número de registro',
      9007 => 'ReBiOMex: búsqueda',
      9008 => 'ReBiOMex: resultados de búsqueda',
      9009 => 'ReBiOMex: error de base de datos',
      9010 => 'ReBiOMex: interface de administrador',
      9011 => 'ReBiOMex: interface de curador',
      9012 => 'ReBiOMex: interface de investigador',
      9013 => 'ReBiOMex: interface de estudiante',
      9014 => 'ReBiOMex: canasta',
      9015 => 'ReBiOMex: consulta taxonomica',
      9016 => 'ReBiOMex: sistema de ayuda',
      9020 => ': ',
      
    },
    en => {
      0001 => 'Test English',
    },
  );

  sub messages 
  {
    my $message_id = shift;
    
    my $message = $mess_db{$language}{$message_id};
    return $message;
  }

  sub paths 
    {
    my $message_id = shift;
    my $os = 'R_L';                               # default OS is linux
    if ($^O =~ /^MSWin/i || $^O =~ /^dos/)        # windows OS detection
    {
      $os = 'R_W';
    } 
    else 
    {
      $os = 'R_L';
    }
    my $message = $mess_db{$os}{$message_id};
    return $message;
  }
  
}

1;