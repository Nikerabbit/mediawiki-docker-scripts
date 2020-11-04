#!/bin/bash

git clone --depth=1 https://gerrit.wikimedia.org/r/mediawiki/core.git mediawiki

pushd mediawiki

tee .env <<EOF
MW_DOCKER_PORT=8080
MW_SCRIPT_PATH=/w
MW_SERVER=http://localhost:8080
MEDIAWIKI_USER=Admin
MEDIAWIKI_PASSWORD=dockerpass
XDEBUG_CONFIG=''
MW_DOCKER_UID=$(id -u)
MW_DOCKER_GID=$(id -g)
EOF

tee docker-compose.override.yml <<'EOF'
version: '3.7'
services:
  mediawiki:
    # On Linux, these lines ensure file ownership is set to your host user/group
    user: "${MW_DOCKER_UID}:${MW_DOCKER_GID}"
  elasticsearch:
    image: docker-registry.wikimedia.org/dev/stretch-elasticsearch:0.0.1
    volumes:
      - esdata:/usr/share/elasticsearch/data
    environment:
      - discovery.type=single-node
    ports:
      - 9200:9200
      - 9300:9300
volumes:
  esdata:
EOF

# Should have some skin to make it less ugly
git clone "https://gerrit.wikimedia.org/r/mediawiki/skins/Vector" skins/Vector
git clone "https://gerrit.wikimedia.org/r/mediawiki/extensions/Elastica" extensions/Elastica
git clone "https://gerrit.wikimedia.org/r/mediawiki/extensions/Translate" extensions/Translate
git clone "https://gerrit.wikimedia.org/r/mediawiki/extensions/UniversalLanguageSelector" extensions/UniversalLanguageSelector

tee composer.local.json <<'EOF'
{
	"extra": {
		"merge-plugin": {
			"include": [
				"extensions/Elastica/composer.json",
				"extensions/Translate/composer.json"
			]
		}
	}
}
EOF

docker-compose up -d
docker-compose exec mediawiki composer update
docker-compose exec mediawiki /bin/bash /docker/install.sh

# This has to be after install
tee -a LocalSettings.php <<'EOF'
wfLoadSkin( 'Vector' );
wfLoadExtensions( [ 'Elastica', 'Translate', 'UniversalLanguageSelector' ] );
$wgTranslateTranslationServices['TTMServer'] = [
	'type' => 'ttmserver',
	'class' => 'ElasticSearchTTMServer',
	'cutoff' => 0.75,
	'public' => true,
	'config' => [ 'servers' => [ [ 'host' => 'elasticsearch', 'port' => 9200 ] ] ],
	'timeout' => 8,
	'use_wikimedia_extra' => true,
];
$wgGroupPermissions['user']['translate'] = true;
$wgGroupPermissions['user']['translate-messagereview'] = true;
$wgGroupPermissions['user']['translate-groupreview'] = true;
$wgGroupPermissions['user']['translate-import'] = true;
$wgGroupPermissions['sysop']['pagetranslation'] = true;
$wgGroupPermissions['sysop']['translate-manage'] = true;
$wgTranslateDocumentationLanguageCode = 'qqq';

EOF

docker-compose exec mediawiki php maintenance/update.php --quick
docker-compose exec mediawiki php extensions/Translate/scripts/ttmserver-export.php
