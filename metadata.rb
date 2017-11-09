name             'base_config'
maintainer       'Pentaho a Hitachi Group Company'
maintainer_email 'chernandez@pentaho.com'
license          'All rights reserved'
description      'Installs/Configures base_config'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.2'

depends 'chef-client'
depends 'sudo'
depends 'mysql', '~> 8.0'
