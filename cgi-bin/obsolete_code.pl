
<TMPL_IF NAME="MENU_OUTPUT">
<!-- actions selector -->
			<TMPL_IF NAME="SEARCH_FIELDS">
			<form class="mainform" action="/cgi-bin/<TMPL_VAR NAME="SCRIPT_NAME">" method="post">
			<fieldset>
				<legend>Buscar usuarios por</legend>
				<TMPL_LOOP NAME="SEARCH_FIELDS">
					<!-- <TMPL_VAR NAME="EXTENDED_SEARCH">  -->
					<!-- <TMPL_VAR NAME="REFERENCE_SEARCH"> -->
					<!-- <TMPL_VAR NAME="REFERENCE_FIELD_NAME"> -->
					<!-- <TMPL_VAR NAME="REFERENCE_ID_NAME"> -->
					<!-- <TMPL_VAR NAME="FIELD_VALUE"> -->
					<!-- <TMPL_VAR NAME="PROBLEM"> -->
					<p>
					<span class="main_form"><label for="<TMPL_VAR NAME="FIELD_NAME">"><TMPL_VAR NAME="FIELD_FULL_NAME">:</label></span>
					<input type="text" size="30" alt="<TMPL_VAR NAME="FIELD_FULL_NAME">"
					name="<TMPL_VAR NAME="FIELD_NAME">" />
					<TMPL_IF NAME="REFERENCE_LINK">
					&nbsp;<a href="/cgi-bin/<TMPL_VAR NAME="SCRIPT_NAME">?table=<TMPL_VAR NAME="REFERENCE_LINK">"><img src="../graphics/icon_select.png" alt="revisar registro" height="16" width="16" border="0" /></a>
					</p>
					</TMPL_IF>
				</TMPL_LOOP>
				<p>
				<input type="hidden" name="action" value="search">
				<input type="hidden" name="table" value="<TMPL_VAR NAME="TABLE_NAME">">
				<input type="hidden" name="users" value="1" />
				<input type="submit" class="searchbutton" value="Buscar" />
				</p>
				<div class="note">* Es posible utilizar los simbolos % y _ como comodínes</div>
			</fieldset>
			</form>
			</TMPL_IF>
			<form action="/cgi-bin/<TMPL_VAR NAME="SCRIPT_NAME">" method="post">
			     <div>
				<label for="submit">Agregar nuevo usuario</label>
				<input type="hidden" name="action" value="add_new_form">
				<input type="hidden" name="table" value="<TMPL_VAR NAME="TABLE_NAME">">
				<input type="hidden" name="users" value="1" />
				<input type="submit" class="formbutton" value="Agregar" />
			    </div>
			 </form>
			<form action="/cgi-bin/<TMPL_VAR NAME="SCRIPT_NAME">" method="post">
			     <div>
				<label for="submit">Mostrar todos los usuarios</label>
				<input type="hidden" name="action" value="search">
				<input type="hidden" name="table" value="<TMPL_VAR NAME="TABLE_NAME">">
				<input type="hidden" name="users" value="1" />
				<input type="submit" class="formbutton" value="Mostrar" />
			    </div>
			 </form>
			<form action="/cgi-bin/<TMPL_VAR NAME="SCRIPT_NAME">" method="post">
			     <div>
				<label for="submit">Regresar a menu inicial del administrador</label>
				<input type="submit" class="formbutton" value="Regresar" />
			    </div> 
			</form>
</TMPL_IF>



sub final_clean 
{
	# first we get string and parse it to lines
	# than we drop all that contains more than one space, like [ \t\n\r]
	# than we return string again
	my $string = shift;
	$string =~ s/\s{2,}?//m;
	return $string
}







HTML <<
= ibug_user_edit.tmpl ===========================================
<!-- user access administration menu -->
<TMPL_IF NAME="USER_LIST">
  <TMPL_IF NAME="USER_EDIT">
      <!-- user edit interface -->
      
        <TMPL_LOOP NAME="USER_LIST">
        
        <form class="modifyform" action="/ibug/cgi-bin/admin.cgi" method="post">
          <fieldset>
          <legend>Modificar la cuenta del usuario</legend>
          <input type="hidden" name="users" value="1" />
          
          <p>
          <label>User_id:</label>
          <TMPL_IF NAME="USER_ID"><TMPL_VAR NAME="USER_ID"><TMPL_ELSE>ID no fue asignado</TMPL_IF>
          </p>
          
          <p>
          <label for="new_user_name">Nombre completo del usuario:</label>
            <TMPL_IF NAME="USER_NAME_PROBLEM">
              <input class="problem" type="text" size="30" maxlength="100" alt="nombre del usuario" name="new_user_name" value="<TMPL_VAR NAME="USER_REAL_NAME">" />
              <br /><span class="bottom_error">
                <img src="../icon_error.png" height="16" width="16" alt="error" border="0" />
                Nombre del usuario especificado esta vacio o ya esta usado para otro usuario de sistema. Especifice otro nombre.
              </span>
            <TMPL_ELSE>
              <input type="text" size="30" maxlength="100" alt="nombre del usuario" name="new_user_name" value="<TMPL_VAR NAME="USER_REAL_NAME">" />
            </TMPL_IF>
          </p>

          <p>
          <label for="new_login">Login:</label>
            <TMPL_IF NAME="USER_LOGIN_PROBLEM">
              <input class="problem" type="text" size="30" maxlength="30" alt="login del usuario" name="new_login" value="<TMPL_VAR NAME="USER_NAME">" />
              <br /><span class="bottom_error">
                <img src="../icon_error.png" height="16" width="16" alt="error" border="0" />
                Login especificado ya esta usado para otro usuario de sistema o esta vacio para el usuario registrado con derechos de acceso. Especifice otro login.
              </span>
            <TMPL_ELSE>
              <input type="text" size="30" maxlength="30" alt="login del usuario" name="new_login" value="<TMPL_VAR NAME="USER_NAME">" />
            </TMPL_IF>
          </p>

          <p>
          <label for="new_institution">Institucion:</label>
          <textarea name="new_institution"  rows="3" cols="50" alt="institucion del usuario"><TMPL_VAR NAME="USER_INSTITUTION"></textarea>
          </p>

          <p>
          <label for="new_comment">Comentario:</label>
          <textarea name="new_comment"  rows="5" cols="50" alt="comentario"><TMPL_VAR NAME="USER_COMMENT"></textarea>
          </p>

          <p>
          <label>Estatus actual del usuario:</label>

            <TMPL_IF NAME="USER_ACCESS">
              usuario registrado con derechos de acceso: <TMPL_VAR NAME="USER_ACCESS">, 
            <TMPL_ELSE>
              usuario sin derechos de acceso registrados, 
            </TMPL_IF>
            <TMPL_IF NAME="USER_LOGIN_TIME">
              conectado <TMPL_VAR NAME="USER_LOGIN_TIME"> 
              <TMPL_IF NAME="USER_LOGIN_HOST">
              desde <TMPL_VAR NAME="USER_LOGIN_HOST">
              </TMPL_IF>
            <TMPL_ELSE>
              desconectado
            </TMPL_IF>
          
            <TMPL_IF NAME="USER_REGISTER_TIME"></TMPL_IF>
            <TMPL_IF NAME="USER_MODIFICATION_TIME"></TMPL_IF>
            <TMPL_IF NAME="USER_REGISTER"></TMPL_IF>
            <TMPL_IF NAME="USER_NO_REGISTER"></TMPL_IF>
          </p>
          
          
          
          <div style="margin-left: 220px;">
          <TMPL_IF NAME="ADD_USER">
            <input type="hidden" name="add_user_complete" value="1" />
            <input type="submit" class="formbutton" value="Registrar" /> <input type="reset" class="formbutton" value="Resetear" />
          <TMPL_ELSE>
            <input type="hidden" name="update_user" value="1" />
            <input type="hidden" name="search_user" value="<TMPL_VAR NAME="USER_ID">" />
            <input type="submit" class="formbutton" value="Guardar" /> <input type="reset" class="formbutton" value="Resetear" />
          </TMPL_IF>
          </div>
          </fieldset>
        </form>
        <form action="/ibug/cgi-bin/admin.cgi" method="post">
          <input type="hidden" name="users" value="1" />
          <span style="margin-left: 0px; position: relative; bottom:61px; left: 432px"><input type="submit" class="formbutton" value="Cancelar" /></span>
        </form>         
      </TMPL_LOOP>
      
    
  <TMPL_ELSE>
      <!-- user output interface -->
      <div class="table_legend">
        <img src="../icon_usradd.png" height="16" width="16" border="0" /> - agregar nueva cuenta del acceso para el usuario
        <br /><img src="../icon_usredit.png" height="16" width="16" border="0" /> - modificar parametros de cuenta del usuario
        <br /><img src="../icon_usrdrop.png" height="16" width="16" border="0" /> - eliminar cuenta del usuario
      </div>
      
      <TMPL_IF NAME="USER_UPDATE">
        <TMPL_IF NAME="USER_UPDATE_SUCCESS">
          <div class="heading">Registro del usuario fue modificado.</div>
        <TMPL_ELSE>
          <div class="heading">Registro del usuario NO fue modificado!</div>
        </TMPL_IF>
      <TMPL_ELSE>
        <TMPL_IF NAME="USER_DELETE">
          <TMPL_IF NAME="USER_DELETE_SUCCESS">
            <div class="heading">Registro del usuario fue eliminado.</div>
          <TMPL_ELSE>
            <div class="heading"><span class="error">Registro del usuario NO fue eleminado!</span></div>
            <TMPL_IF NAME="USER_DELETE_REFERENCE_PROBLEM">
            <div class="heading"><span class="error">Intento de eliminacion del usuario de la tabla fue rechazado por presencia de referencias al registro del usuario en otras tablas.</span></div>
            </TMPL_IF>
          </TMPL_IF>

        <TMPL_ELSE>
          <div class="heading">Fueron encontrados los siguentes registros de los usuarios</div>
        </TMPL_IF>
      </TMPL_IF>
      

      <table class="style1" width="100%">
      <tr>
        <th width="3%">User_id</th>
        <th width="10%">Login</th>
        <th width="12%">Nombre del usuario</th>
        <th width="20%">Institucion</th>
        <th width="20%">Comentario</th>
        <th width="20%">Estatus actual del usuario</th>
        <th width="15%">Fecha de registro de la cuenta/acceso del usuario</th>
        <th width="5%">Acciones</th>
      </tr>
      <TMPL_LOOP NAME="USER_LIST">
      <tr>
        <td><TMPL_IF NAME="USER_ID"><TMPL_VAR NAME="USER_ID"><TMPL_ELSE>ID de nuevo usuario</TMPL_IF></td>
        <td><TMPL_IF NAME="USER_NAME"><TMPL_VAR NAME="USER_NAME"><TMPL_ELSE>&nbsp;</TMPL_IF></td>
        <td><TMPL_IF NAME="USER_REAL_NAME"><TMPL_VAR NAME="USER_REAL_NAME"><TMPL_ELSE>&nbsp;</TMPL_IF></td>
        <td><TMPL_IF NAME="USER_INSTITUTION"><TMPL_VAR NAME="USER_INSTITUTION"><TMPL_ELSE>&nbsp;</TMPL_IF></td>
        <td><TMPL_IF NAME="USER_COMMENT"><TMPL_VAR NAME="USER_COMMENT"><TMPL_ELSE>&nbsp;</TMPL_IF></td>
        <td>
          <TMPL_IF NAME="USER_ACCESS">
            usuario registrado con derechos de acceso: <TMPL_VAR NAME="USER_ACCESS">, 
          <TMPL_ELSE>
            usuario sin derechos de acceso registrados, 
          </TMPL_IF>
          <TMPL_IF NAME="USER_LOGIN_TIME">
            conectado <TMPL_VAR NAME="USER_LOGIN_TIME"> 
            <TMPL_IF NAME="USER_LOGIN_HOST">
            desde <TMPL_VAR NAME="USER_LOGIN_HOST">
            </TMPL_IF>
          <TMPL_ELSE>
            desconectado
          </TMPL_IF>
        </td>
        <td>
          <TMPL_IF NAME="USER_REGISTER_TIME"><TMPL_VAR NAME="USER_REGISTER_TIME"><TMPL_ELSE>-</TMPL_IF>/<TMPL_IF NAME="USER_MODIFICATION_TIME"><TMPL_VAR NAME="USER_MODIFICATION_TIME"><TMPL_ELSE>-</TMPL_IF>
        </td>
        <td>
          <TMPL_IF NAME="USER_NO_REGISTER">
            &nbsp;
          <TMPL_ELSE>
            <TMPL_IF NAME="USER_REGISTER">
              <a href="/ibug/cgi-bin/admin.cgi?users=1&edit_user=1&search_user=<TMPL_VAR NAME="USER_ID">"><img src="../icon_usredit.png" alt="modificar la cuenta del usuario" height="16" width="16" border="0" /></a>&nbsp;
              <a href="/ibug/cgi-bin/admin.cgi?users=1&delete_user=1&search_user=<TMPL_VAR NAME="USER_ID">"><img src="../icon_usrdrop.png" alt="eliminar la cuenta del usuario" height="16" width="16" border="0" /></a>&nbsp;
              <a href="/ibug/cgi-bin/admin.cgi?user_access=1&edit_login=1&search_user=<TMPL_VAR NAME="USER_ID">"><img src="../icon_usradd.png" alt="agregar parametros de acceso del usuario" height="16" width="16" border="0" /></a>
            <TMPL_ELSE>
              <a href="/ibug/cgi-bin/admin.cgi?users=1&edit_user=1&search_user=<TMPL_VAR NAME="USER_ID">"><img src="../icon_usredit.png" alt="redactar cuenta del usuario" height="16" width="16" border="0" /></a>&nbsp;
              <a href="/ibug/cgi-bin/admin.cgi?users=1&delete_user=1&search_user=<TMPL_VAR NAME="USER_ID">"><img src="../icon_usrdrop.png" alt="eliminar cuenta del usuario" height="16" width="16" border="0" /></a>
            </TMPL_IF>
          </TMPL_IF>
        </td>
        <TMPL_IF NAME="ADD_USER"></TMPL_IF>
      </tr>
      </TMPL_LOOP>
      </table>
  </TMPL_IF>
<TMPL_ELSE>
    <TMPL_IF NAME="USER_LIST_NO_MATCH">
      <div class="heading">No fueron encontrados usuarios registrados en sistema con los parametros de busqueda especificados</div>
    </TMPL_IF>
</TMPL_IF>


<table width="100%">
  <tr>
    <td width="400px">
    <form action="/ibug/cgi-bin/admin.cgi" method="post">
      <div>
        <label for="submit">Regresar a menu inicial de interface de administrador</label>
        <input type="submit" class="formbutton" value="Regresar" />
      </div>
    </form>

    <form action="/ibug/cgi-bin/admin.cgi" method="post">
      <div>
        <label for="submit"><img src="../icon_usrlist.png" height="16" width="16" border="0" />Mostrar la tabla de todos los usuarios registrados en sistema</label>
        <input type="hidden" name="users" value="1" /><input type="hidden" name="search_user" value="all" /> <input type="submit" class="formbutton" value="Mostrar tabla" />
      </div>
    </form>
    
    <form action="/ibug/cgi-bin/admin.cgi" method="post">
      <div>
        <label for="submit"><img src="../icon_usradd.png" height="16" width="16" border="0" />Registrar nuevo usuario</label>
        <input type="hidden" name="users" value="1" /><input type="hidden" name="add_user" value="1" /> <input type="submit" class="formbutton" value="Registrar" />
      </div>
    </form>   
    
    </td>
    <td width="400px">
    <form action="/ibug/cgi-bin/admin.cgi" method="post">
      <div class="unit_form">
      <fieldset>
        <legend>Buscar usuarios para modificar</legend>
          <div class="main_form">
          <label for="search_login">por su login </label>
          <input type="text" size="10" maxlength="30" alt="login del ususrio para buscar" name="search_login" />
          <br />
          <label for="search_nombre">por su nombre </label>
          <input type="text" size="10" maxlength="100" alt="nombre del ususrio para buscar" name="search_user_name" />
          <br />
          <label for="search_fecha">por fecha de registro (aaaa-mm-dd)</label>
          <input type="text" size="10" maxlength="10" alt="fecha de registro del ususrio para buscar" name="search_user_date" />
          <input type="hidden" name="users" value="1" />
          <input type="submit" class="searchbutton" value="Buscar" />
          </div>
        <div class="note">* Es posible utilizar los simbolos % y ? como comodÃ­nes</div>
      </fieldset>
      </div>
    </form>
    </td>
  </tr>
</table>

= end of ibug_user_edit.tmpl ===========================================
HTML

= admin.cgi ===========================================

	# normally access to list is using user_id, login, user_name, date_mod, but for new user still not in db there are one more way to enter just with add_user or add_user_complete
	if (	param("search_user") 
		|| param("search_login") 
		|| param("search_user_name")
		|| param("search_user_date")
		|| param("add_user")
		|| param("add_user_complete"))
	{
		
		# user list
		my ($new_user_login_problem,$new_user_name_problem,$new_institution_problem,$new_comment_problem,$problem) = '';
		my $clause = &clause_user();

		# for users that are in databaseand have user_id - check with direct reference to db, and store
		if (param("update_user")) {
			my @user_list_ref_1 = &user_list($clause,$template,$dbh); # first time call to check values
			if (scalar @user_list_ref_1) # checks if we have at least one value
			{
				my $user_ref_1 = shift @user_list_ref_1;
				if (	param("new_login") ) {
					# we have new login to check and to modify using db values
					my $user_id = &get_user_id_by(scalar &escape_input(&trim(param("new_login"))),undef,$template,$dbh); # check if we have same login anywhere
					if ($user_id) { 
						if ( defined $$user_ref_1->{user_login} ) {
							if ( &check_update($$user_ref_1->{user_login},&escape_input(&trim(param("new_login")))) ) {
								$new_user_login_problem = 1; $problem = 1;
							}
						} else {
							$new_user_login_problem = 1; $problem = 1;
						};
					};
				} elsif (defined $$user_ref_1->{user_login}) {
					my $user_password = ();
					(undef,undef,$user_password) = &get_user_id($$user_ref_1->{user_login},$template,$dbh);
					if ($user_password) { $new_user_login_problem = 1; $problem = 1;} # when password is defined - login should be defined
				};
				if ( param("new_user_name") ) {
					# we have new user name to check and to modify usig db values
					my $user_id = &get_user_id_by(undef,scalar &trim(param("new_user_name")),$template,$dbh);
					if ($user_id) { 
						if ( defined $$user_ref_1->{user_name} ) {
							if ( &check_update($$user_ref_1->{user_name},&trim(param("new_user_name"))) ) {
								$new_user_login_problem = 1; $problem = 1;
							};
						} else {
							$new_user_login_problem = 1; $problem = 1;
						};
					};
				} else {
					$new_user_name_problem = 1; $problem = 1;
				};
				if ( param("new_institution") ) {
					# we have new institution to check and to modify
					if (!(param("new_institution"))) { $new_institution_problem = 1; $problem = 1;};
				}
				if ( param("new_comment") ) {
					# we have new institution to check and to modify
					if (!(param("new_comment"))) { $new_comment_problem = 1; $problem = 1;};
				}
				&user_update_check($problem,$$user_ref_1->{user_id},$template,$dbh);
			}
		}
		
		# for users not in dataase, with form just filled in - check without direct reference to db and store
		if (param("add_user_complete")) {
				if (	param("new_login")) {
					# we have new login to check and to modify
					my $user_id = &get_user_id_by(scalar &escape_input(&trim(param("new_login"))),undef,$template,$dbh); # check if we have same login anywhere
					if ($user_id) { $new_user_login_problem = 1; $problem = 1;}
				}
				if (	param("new_user_name")) {
					# we have new user name to check and to modify
					my $user_id = &get_user_id_by(undef,scalar &trim(param("new_user_name")),$template,$dbh); # check if we have same user name anywhere
					if ($user_id) { $new_user_name_problem = 1; $problem = 1;};
				} else {
					# user_name is empty (imposible for new registration)
					{ $new_user_name_problem = 1; $problem = 1;};
				}
				if (	param("new_institution")) {
					# we have new institution to check and to modify
					if (!(param("new_institution"))) { $new_institution_problem = 1; $problem = 1;};
				}
				if (	param("new_comment")) {
					# we have new institution to check and to modify
					if (!(param("new_comment"))) { $new_comment_problem = 1; $problem = 1;};
				}
				&user_update_check($problem,0,$template,$dbh);
		}


		
		# universal part for all modalities (output, edit or add new)
		my @user_list_ref = &user_list($clause,$template,$dbh); # second time call to print
		if (scalar @user_list_ref || param("add_user") || param("add_user_complete")) { 
			my @user_list = ();
			my $add_user_flag = 0;
			# good idea - we add one emty item in case of empty set to use same part of code to output new user form
			if ((scalar @user_list_ref < 1) && (param("add_user_complete") || param("add_user"))) { 
				my $line_ref = ();
				$line_ref = {'user_id' => '0'};
				push(@user_list_ref, \$line_ref); 
				$add_user_flag = 1;
			};
			foreach my $user_ref (@user_list_ref) {
				my %user = ();
				# fill in fields with database values - works for one or multiple lines in loop
				if (defined $$user_ref->{user_id}) {$user{USER_ID} = escapeHTML($$user_ref->{user_id});};
				if (defined $$user_ref->{user_login}) {$user{USER_NAME} = escapeHTML($$user_ref->{user_login});};
				if (defined $$user_ref->{user_name}) {$user{USER_REAL_NAME} = escapeHTML($$user_ref->{user_name});};
				if (defined $$user_ref->{institution}) {$user{USER_INSTITUTION} = escapeHTML($$user_ref->{institution});};
				if (defined $$user_ref->{comment}) {$user{USER_COMMENT} = escapeHTML($$user_ref->{comment});};
				if (defined $$user_ref->{user_access}) {$user{USER_ACCESS} = escapeHTML($$user_ref->{user_access});};
				if (defined $$user_ref->{date_reg}) {$user{USER_REGISTER_TIME} = escapeHTML($$user_ref->{date_reg});};
				if (defined $$user_ref->{date_mod}) {$user{USER_MODIFICATION_TIME} = escapeHTML($$user_ref->{date_mod});};
				if (defined $$user_ref->{last_login}) {$user{USER_LOGIN_TIME} = escapeHTML($$user_ref->{last_login});};
				if (defined $$user_ref->{last_login_host}) {$user{USER_LOGIN_HOST} = escapeHTML($$user_ref->{last_login_host});};
				# fill in fields wih user-specified values (in case that we have user edit mode caused by problem) - works when we have only one line in loop
				if (($problem && ((scalar @user_list_ref) == 1)) || param("add_user_complete")) {
					if (param("new_login")) {$user{USER_NAME} = escapeHTML(&escape_input(&trim(param("new_login"))));};
					if (param("new_user_name")) {$user{USER_REAL_NAME} = escapeHTML(&trim(param("new_user_name")));};
					if (param("new_institution")) {$user{USER_INSTITUTION} = escapeHTML(&trim(param("new_institution")));};
					if (param("new_comment")) {$user{USER_COMMENT} = escapeHTML(&trim(param("new_comment")));};
					if ($new_user_login_problem) {$user{USER_LOGIN_PROBLEM} = 1;};
					if ($new_user_name_problem) {$user{USER_NAME_PROBLEM} = 1;};
				};
				# additional fields in loop
				# USER_REGISTER - flag to set access account options to user menu (should be inside loop)
				# ADD_USER - flag to set mode ofnew user registration (should be inside loop)
				if (!($$user_ref->{user_access})) { $user{USER_REGISTER} = 1; };
				if (param("add_user_complete") || param("delete_user")) { $user{USER_NO_REGISTER} = 1; };
				if ($add_user_flag) {$user{ADD_USER} = 1;};
				push(@user_list, \%user);
			}
			$template->param(USER_LIST => \@user_list);
		} else {
			$template->param(USER_LIST_NO_MATCH => 1);
		}
		
		# delete procedure should be after autput of values to leave values stored to display later
		if (	param("delete_user") 
			&& param("search_user")) {
			# deleting of user account
			$template->param(USER_DELETE => 1);
			my ($match_count,$reference_problem) = &user_delete(&escape_numeric_input(param("search_user")),$template,$dbh);
			if ( $match_count ) {
				$template->param(USER_DELETE_SUCCESS => 1);
			}
			if ( $reference_problem ) {
				$template->param(USER_DELETE_REFERENCE_PROBLEM => 1);
			}
		}	

		if (param("edit_user") || param("add_user")) {
			$template->param(USER_EDIT => 1);
		}
	}
	
	sub clause_user {
	# sub to make conditions for search in user table
		my $clause_string = '';
		if ((defined param("search_user")) && (param("search_user") =~ /(\d+)/i)) {
				# search for user specified by user_id
				$clause_string .= "user.user_id = '$1' AND ";
		}
		if (param("add_user")) {
				# search for user specified by user_id
				$clause_string .= "user.user_id = 0 AND ";
		}
		if (param("search_login")) {
				# search for user specified by login
				my $search_login = &escape_input(param("search_login"));
				$clause_string .= "user.user_login LIKE '$search_login' AND ";
		}
		if (param("search_user_name")) {
				# search for user specified by user name
				my $search_user_name = &escape_input_1(param("search_user_name"));
				$clause_string .= "user.user_name LIKE '$search_user_name' AND ";
		}
		if (param("search_user_date")) {
				# search for user specified by date
				my $search_user_date = &escape_date(param("search_user_date"));
				$clause_string .= "user.date_mod LIKE '$search_user_date' AND ";
		}
		if (param("search_user_access_date")) {
				# search for user specified by date
				my $search_user_date = &escape_date(param("search_user_access_date"));
				$clause_string .= "user_access.date_mod LIKE '$search_user_date' AND ";
		}
	return $clause_string;
};

sub user_update_check {
	# sub to check mdifications of user table and update it if need
	my ($problem,$id,$template,$dbh) = @_;
	if (!$problem) {
		# there is no formal problem with data
		# first we need to check if some modification necessary, than to realize modification
		$template->param(USER_UPDATE => 1); # flag of update attempt
		my $mod = 0;
		if ($id) {
			my $cl = "user.user_id = '$id' AND "; # making condition to search user by his user_id
			my @user_list_ref = &user_list($cl,$template,$dbh);
			if (scalar @user_list_ref) # checks if we have at least one value and if so realize serie of comparative test for different fields
			{
				my $user_ref = shift @user_list_ref;
				if ( &check_update($$user_ref->{user_login},&escape_input(&trim(param("new_login")))) ) { $mod++; };
				if ( &check_update($$user_ref->{user_name},&trim(param("new_user_name"))) ) { $mod++; };
				if ( &check_update($$user_ref->{institution},&trim(param("new_institution"))) ) { $mod++; };
				if ( &check_update($$user_ref->{comment},&trim(param("new_comment"))) ) { $mod++; };
			};
		} else {
			$mod++; # if we have no id than it should be a new value and iti is necessary to set modify flag
		};
		if ($mod) {
			# user update or add to database
			if ( &user_update($id,
				&escape_input(&trim(param("new_login"))),
				&trim(param("new_user_name")),
				&trim(param("new_institution")),
				&trim(param("new_comment")),
				$template,
				$dbh)) {
					$template->param(USER_UPDATE_SUCCESS => 1); # flag of actual update success
			};
		};
	} else {
			#we have some problem with input data and need to request them ones more
			$template->param(USER_EDIT => 1);
	}
};


??


<TMPL_IF NAME="TABLE_OUTPUT">
<!-- table output -->
<TMPL_IF NAME="TABLE">
<div class="table_legend"><img src="../icon_usredit.png" alt="redactar registro del usuario" height="16" width="16" border="0" /> - modificar registro del usuario
<br /><img src="../icon_usrdrop.png" alt="eliminar registro del usuario" height="16" width="16" border="0" /> - eliminar registro del usuario
<br /><img src="../icon_select.png" alt="revisar registro" height="16" width="16" border="0" /> - revisar registro de referencia en tabla externa
<br /><img src="../icon_usradd.png" alt="agregar o morificar cuenta de aceso del usuario" height="16" width="16" border="0" /> - agregar o modificar cuenta de acceso para el usuario
</div>
<TMPL_INCLUDE NAME="ibug_table_admin_prevnext.tmpl">
  <TMPL_IF NAME="WIDE_TABLE"><table class="style1" width="1024px"><TMPL_ELSE><table class="style1" width="100%"></TMPL_IF>
  <tr>  
    <TMPL_LOOP NAME="TABLE_HEADER">
        <th><TMPL_VAR NAME="COLUMN_NAME"></th>
    </TMPL_LOOP>
    <TMPL_IF NAME="ACTION_SEARCH">
	<th>Acciones</th>
    <TMPL_ELSE>
	<th>Acciones con registro seleccionado</th>
    </TMPL_IF>
  </tr>  

<TMPL_IF NAME="ACTION_SEARCH">
  <!-- table content for search request -->
  <TMPL_LOOP NAME="TABLE">
  <tr>  
    <TMPL_LOOP NAME="TABLE_RAW">
        <td>        
          <TMPL_VAR NAME="FIELD">
	<TMPL_IF NAME="REFERENCE_LINK">
	&nbsp;<a class="reference_button" href="/ibug/cgi-bin/admin.cgi?users=1&action=search&table=<TMPL_VAR NAME="REFERENCE_LINK">&s_id=<TMPL_VAR NAME="FIELD">"><img src="../icon_select.png" alt="revisar registro" height="16" width="16" border="0" /></a>
	</TMPL_IF>
        </td>
    </TMPL_LOOP>
	    <td>
	    <a href="/ibug/cgi-bin/admin.cgi?users=1&action=modify_form&table=<TMPL_VAR NAME="TABLE_NAME">&s_id=<TMPL_VAR NAME="S_ID">"><img src="../icon_usredit.png" alt="redactar registro del usuario" height="16" width="16" border="0" /></a>&nbsp;
	    <a href="/ibug/cgi-bin/admin.cgi?users=1&action=eliminate&table=<TMPL_VAR NAME="TABLE_NAME">&s_id=<TMPL_VAR NAME="S_ID">"><img src="../icon_usrdrop.png" alt="eliminar registro del usuario" height="16" width="16" border="0" /></a>&nbsp;
	    <a href="/ibug/cgi-bin/admin.cgi?user_access=1&edit_login=1&search_user=<TMPL_VAR NAME="S_ID">"><img src="../icon_usradd.png" alt="agregar o morificar cuenta de aceso del usuario" height="16" width="16" border="0" /></a>&nbsp;
	    </td>
  </tr>
  </TMPL_LOOP>
<TMPL_ELSE>
 <!-- table content in special cases such as report of exit in modification or add - originally without controls -->
  <TMPL_LOOP NAME="TABLE">
  <tr>  
    <TMPL_LOOP NAME="TABLE_RAW">
        <td>        
          <TMPL_VAR NAME="FIELD">
	<TMPL_IF NAME="REFERENCE_LINK">
	&nbsp;<a class="reference_button" href="/ibug/cgi-bin/admin.cgi?users=1&action=search&table=<TMPL_VAR NAME="REFERENCE_LINK">&s_id=<TMPL_VAR NAME="FIELD">"><img src="../icon_select.png" alt="revisar registro" height="16" width="16" border="0" /></a>
	</TMPL_IF>
        </td>
    </TMPL_LOOP>
	    <td>
	    <a href="/ibug/cgi-bin/admin.cgi?users=1&action=modify_form&table=<TMPL_VAR NAME="TABLE_NAME">&s_id=<TMPL_VAR NAME="S_ID">"><img src="../icon_usredit.png" alt="redactar registro del usuario" height="16" width="16" border="0" /></a>&nbsp;
	    <a href="/ibug/cgi-bin/admin.cgi?users=1&action=eliminate&table=<TMPL_VAR NAME="TABLE_NAME">&s_id=<TMPL_VAR NAME="S_ID">"><img src="../icon_usrdrop.png" alt="eliminar registro del usuario" height="16" width="16" border="0" /></a>&nbsp;
	    <a href="/ibug/cgi-bin/admin.cgi?user_access=1&edit_login=1&search_user=<TMPL_VAR NAME="S_ID">"><img src="../icon_usradd.png" alt="agregar o morificar cuenta de aceso del usuario" height="16" width="16" border="0" /></a>&nbsp;
	    </td>
  </tr>
  </TMPL_LOOP>
</TMPL_IF>
  </table>

<TMPL_INCLUDE NAME="ibug_table_admin_prevnext.tmpl">
</TMPL_IF>
<!-- end of table output -->
</TMPL_IF>

<TMPL_IF NAME="FORM_OUTPUT">
<!-- form output -->
<TMPL_IF NAME="FORM">
<form class="modifyform" action="/ibug/cgi-bin/admin.cgi" method="post">
<fieldset>
<legend>Modificar cuentadel usuario</legend>
<TMPL_LOOP NAME="FORM">
	<p>
	<label for="<TMPL_VAR NAME="FIELD_NAME">"><TMPL_VAR NAME="FIELD_FULL_NAME">:</label>
	<TMPL_IF NAME="EDITABLE">
		<!-- ------------------------------ field --------------------------- -->
		<TMPL_IF NAME="TYPE_FIELD">
		<TMPL_IF NAME="OBLIGATORY">*</TMPL_IF>
		<input type="text" size="30" maxlength="<TMPL_VAR NAME="LENGTH">" alt="<TMPL_VAR NAME="FIELD_VALUE">"
		<TMPL_IF NAME="PROBLEM">class="problem"</TMPL_IF> 
		name="<TMPL_VAR NAME="FIELD_NAME">" value="<TMPL_VAR NAME="FIELD_VALUE">" />
		<TMPL_IF NAME="REFERENCE_LINK">
			&nbsp;R
			<TMPL_IF NAME="FIELD_VALUE">
			&nbsp;<a href="/ibug/cgi-bin/admin.cgi?action=search&table=<TMPL_VAR NAME="REFERENCE_LINK">&s_id=<TMPL_VAR NAME="FIELD_VALUE">"><img src="../icon_select.png" alt="revisar registro" height="16" width="16" border="0" /></a>
			<TMPL_ELSE>
			&nbsp;<a href="/ibug/cgi-bin/admin.cgi?table=<TMPL_VAR NAME="REFERENCE_LINK">"><img src="../icon_select.png" alt="revisar registro" height="16" width="16" border="0" /></a>
			</TMPL_IF>
		</TMPL_IF>
                    <TMPL_IF NAME="PROBLEM">
			<br /><span class="form_error"><img src="../icon_error.png" height="16" width="16" alt="error" border="0" />&nbsp;<TMPL_VAR NAME="PROBLEM"></span>
                    </TMPL_IF>
		<!-- ------------------------------ end field --------------------------- -->
                   <TMPL_ELSE>
			<!-- ------------------------------ text --------------------------- -->
			<TMPL_IF NAME="TYPE_TEXT"> 
			<TMPL_IF NAME="OBLIGATORY">*</TMPL_IF>
<!-- textarea, should be without margin -->
<textarea name="<TMPL_VAR NAME="FIELD_NAME">" 
<TMPL_IF NAME="PROBLEM">class="problem"</TMPL_IF> 
rows="3" cols="50" alt="<TMPL_VAR NAME="FIELD_VALUE">">
<TMPL_VAR NAME="FIELD_VALUE"></textarea>
			<TMPL_IF NAME="PROBLEM">
				<br /><span class="form_error"><img src="../icon_error.png" height="16" width="16" alt="error" border="0" />&nbsp;<TMPL_VAR NAME="PROBLEM"></span>
			</TMPL_IF>
			<!-- ------------------------------ end text --------------------------- -->
			<TMPL_ELSE>
				<!-- ------------------------------ enum or set --------------------------- -->
				<TMPL_IF NAME="TYPE_ENUM">
				<TMPL_IF NAME="OBLIGATORY">*</TMPL_IF>
				<select name="<TMPL_VAR NAME="FIELD_NAME">" 
				<TMPL_IF NAME="PROBLEM">class="problem"</TMPL_IF>
				<TMPL_IF NAME="MULTIPLE">multiple size="6"<TMPL_ELSE>size="1"</TMPL_IF>
				alt="<TMPL_VAR NAME="FIELD_VALUE">" value="<TMPL_VAR NAME="FIELD_VALUE">">
				<TMPL_LOOP NAME="TYPE_ENUM">
					<TMPL_IF NAME="SELECTED">
						<option selected value="<TMPL_VAR NAME="ENUM_VALUE">">
					<TMPL_ELSE>
						<option value="<TMPL_VAR NAME="ENUM_VALUE">">
					</TMPL_IF>
					<TMPL_IF NAME="ENUM_TEXT"><TMPL_VAR NAME="ENUM_TEXT"><TMPL_ELSE><TMPL_VAR NAME="ENUM_VALUE"></TMPL_IF>
					</option>
				</TMPL_LOOP>
				</select>
				<TMPL_IF NAME="PROBLEM">
					<br /><span class="form_error"><img src="../icon_error.png" height="16" width="16" alt="error" border="0" />&nbsp;<TMPL_VAR NAME="PROBLEM"></span>
				</TMPL_IF>
				<!-- ------------------------------ end enum or set --------------------------- -->
				<TMPL_ELSE>
					<!-- ------------------------------ checkbox --------------------------- -->
					<TMPL_IF NAME="TYPE_CHECKBOX">
					<TMPL_IF NAME="OBLIGATORY">*</TMPL_IF>
					<input type="checkbox" alt="<TMPL_VAR NAME="FIELD_VALUE">"	<TMPL_IF NAME="PROBLEM">class="problem"</TMPL_IF> name="<TMPL_VAR NAME="FIELD_NAME">" <TMPL_IF NAME="FIELD_VALUE">checked value="<TMPL_VAR NAME="FIELD_VALUE">"</TMPL_IF> />
						<!-- <TMPL_VAR NAME="REFERENCE_LINK"> <TMPL_VAR NAME="LENGTH"> -->
					<TMPL_IF NAME="PROBLEM">
						<br /><span class="form_error"><img src="../icon_error.png" height="16" width="16" alt="error" border="0" />&nbsp;<TMPL_VAR NAME="PROBLEM"></span>
					</TMPL_IF>				
					<!-- ------------------------------ end checkbox --------------------------- -->
					<TMPL_ELSE>
						<!-- ------------------------------ something here --------------------------- -->
					</TMPL_IF>
				</TMPL_IF>
			</TMPL_IF>
		</TMPL_IF>
          <TMPL_ELSE>
		<TMPL_IF NAME="FIELD_VALUE">
			<TMPL_VAR NAME="FIELD_VALUE">
			<input type="hidden" name="<TMPL_VAR NAME="FIELD_NAME">" value="<TMPL_VAR NAME="FIELD_VALUE">" />
		<TMPL_ELSE>
			Campo vacio
		</TMPL_IF>
          </TMPL_IF>
          </p>   
</TMPL_LOOP>

<div class="note">* - campo obligatorio; R - campo con referencia a tabla externa</div>

<input type="hidden" name="users" value="1" />
<input type="hidden" name="table" value="<TMPL_VAR NAME="TABLE_NAME">">
<TMPL_IF NAME="ACTION_MODIFYFORM">
	<input type="hidden" name="action" value="modify">
	<input type="hidden" name="s_id" value="<TMPL_VAR NAME="S_ID">">
	<label for="submit">&nbsp;</label>
	<input type="submit" class="formbutton" value="Modificar" />
</TMPL_IF>
<TMPL_IF NAME="ACTION_MODIFYPROBLEM">
	<input type="hidden" name="action" value="modify">
	<input type="hidden" name="s_id" value="<TMPL_VAR NAME="S_ID">">
	<label for="submit">&nbsp;</label>
	<input type="submit" class="formbutton" value="Modificar" />
</TMPL_IF>
<TMPL_IF NAME="ACTION_ADDFORM">
	<input type="hidden" name="action" value="add_new">
	<label for="submit">&nbsp;</label>
	<input type="submit" class="formbutton" value="Agregar" />
</TMPL_IF>
<TMPL_IF NAME="ACTION_ADDPROBLEM">
	<input type="hidden" name="action" value="add_new">
	<label for="submit">&nbsp;</label>
	<input type="submit" class="formbutton" value="Agregar" />
</TMPL_IF>

</fieldset>
</form>
</TMPL_IF>
<!-- end of form output -->
</TMPL_IF>



HEADER AJAX
// TO DO: try to resolve multithread requests issues with  Chris Marshall ajax_threads.js
function xmlhttpGet_old(strURL,tag_id) {
    var xmlHttpReq = false;
    var self = this;
    var bComplete = false;

  // creating xmlHttp object (browser dependent)
  try { self.xmlHttpReq = new ActiveXObject("Msxml2.XMLHTTP"); }
  catch (e) { try { self.xmlHttpReq = new ActiveXObject("Microsoft.XMLHTTP"); } // IE 5
  catch (e) { try { self.xmlHttpReq = new XMLHttpRequest(); } // Mozilla/Safari
  catch (e) { self.xmlHttpReq = false; }}}
  
  if (!self.xmlHttpReq) { updatepage(' [AJAX error] ',tag_id); return null; }

  self.xmlHttpReq.open('GET', strURL, true);
  strURL = "";

  self.xmlHttpReq.onreadystatechange = function(){
  if (self.xmlHttpReq.readyState == 4 && !bComplete)
    {
    bComplete = true;
    if (self.xmlHttpReq.status == 200) {
      updatepage(self.xmlHttpReq.responseText,tag_id);
    } else {
      updatepage(' [AJAX error] ',tag_id);
    };
  }};

    self.xmlHttpReq.send(strURL);
 //   catch(z) { return false; }
  return true;
}