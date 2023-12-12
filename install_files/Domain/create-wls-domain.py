#
# WebLogic on Docker Default Domain
#
import os

# ==============================================
domain_name = os.getenv('DOMAIN')
logs = os.getenv('LOGS')
admin_name  = os.environ.get("ADMIN_NAME", "AdminServer")
admin_listen_port   = int(os.environ.get("ADMIN_LISTEN_PORT", "8005"))
domain_path  = '/u01/oracle/Domains/aserver/%s' % domain_name
production_mode = os.environ.get("PRODUCTION_MODE", "prod")
administration_port_enabled = os.environ.get("ADMINISTRATION_PORT_ENABLED", "true")
administration_port = int(os.environ.get("ADMINISTRATION_PORT", "9002"))

print('domain_name                 : [%s]' % domain_name);
print('admin_listen_port           : [%s]' % admin_listen_port);
print('domain_path                 : [%s]' % domain_path);
print('production_mode             : [%s]' % production_mode);
print('admin name                  : [%s]' % admin_name);
print('administration_port_enabled : [%s]' % administration_port_enabled);
print('administration_port         : [%s]' % administration_port);

# Open default domain template
# ============================
readTemplate("/u01/oracle/Middleware/" + domain_name + "/wlserver/wlserver/common/templates/wls/wls.jar")

set('Name', domain_name)
setOption('DomainName', domain_name)

# Set Administration Port 
# =======================
if administration_port_enabled != "false":
   set('AdministrationPort', administration_port)
   set('AdministrationPortEnabled', 'true')

# Disable Admin Console
# --------------------
# cmo.setConsoleEnabled(true)
 
# Configure the Administration Server and SSL port.
# =================================================
create(domain_name, 'Log')
cd ('Log/' + domain_name )
set('FileName', logs + '/' + domain_name + '.log')
set('RotationType', 'none')
cd('../..')
cd('/Servers/AdminServer')
set('Name', admin_name)
set('ListenAddress', '')
set('ListenPort', admin_listen_port)
if administration_port_enabled != "false":
   create(admin_name, 'SSL')
   create(admin_name, 'Log')
   create(admin_name, 'ServerStart')
   cd('SSL/' + admin_name)
   set('Enabled', 'True')
   set('ListenPort', 8006)
   cd('../..')
   cd('Log/' + admin_name)
   set('RotationType', 'none')
   set('FileName', logs + '/AdminServer.log')
   cd('../..')
   cd('ServerStart/' + admin_name)
   set('Arguments', '-Xms1024M -Xmx2048M -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=512M -Dweblogic.Stdout=' + logs + '/AdminServer.out -Dweblogic.security.SSL.ignoreHostnameVerification=true')
   cd('../..')
   create(admin_name, 'WebServer')
   cd('WebServer/' + admin_name)
   create(admin_name, 'WebServerLog')
   cd('WebServerLog/' + admin_name)
   set('FileName', logs + '/access.log')
   set('RotationType', 'none')
# Define the user password for weblogic
# =====================================
cd(('/Security/%s/User/weblogic') % domain_name)
cmo.setName(username)
cmo.setPassword(password)

# Write the domain and close the domain template
# ==============================================
setOption('OverwriteDomain', 'true')
setOption('ServerStartMode',production_mode)

# Write Domain
# ============
writeDomain(domain_path)
closeTemplate()

# Exit WLST
# =========
exit()
