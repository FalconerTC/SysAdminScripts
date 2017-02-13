import configparser
from configparser import ExtendedInterpolation
config = configparser.ConfigParser(interpolation=ExtendedInterpolation())
config['DEFAULT'] = {}
# ${section:key} syntax below designates interpolation of key from section
config['Common'] = {'home_dir': '/home/spig',
                    'servers_dir': '${home_dir}/servers',
                    'scripts_dir': '${home_dir}/scripts',
                    'settings_dir': '${scripts_dir}/settings',
                    'log_dir': '${home_dir}/log'}
config['Execs'] = {'control': '${scripts_dir}/control.py',
                   'steam_cmd': '${home_dir}/games/steamCMD/steamcmd.sh'}
config['Starbound'] = {'game_dir': '${Common:servers_dir}/starbound',
                       'game_path': '${game_dir}/linux',
                       'game_id': 211820,
                       'screen_name': 'Starbound_Server',
                       'start_cmd': '${game_path}/starbound_server',
                       'steam_username': 'spider_pig448'}
config['KillingFloor'] = {'game_dir': '${Common:servers_dir}/killingfloor',
                          'game_path': '${game_dir}/System',
                          'game_id': 215360,
                          'screen_name': 'KillingFloor_Server',
                          'start_flags': 'KF-farm.rom?VACSecured=true?AdminName=spig?AdminPassword=nyanpasu',
                          'start_cmd': '${game_path}/ucc-bin server ${start_flags} -ini=Killingfloor.ini -nohomedir',
                          'steam_username': 'spig_server'}

with open('./settings/config.cfg', 'w') as configfile:
    config.write(configfile)