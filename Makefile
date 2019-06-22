backup_tmp=backup/$(shell date --iso=minutes)

all: make_dirs

make_dirs:
	mkdir -p backup
	mkdir -p data

make_backup: make_dirs
	mkdir -p ${backup_tmp}
	mv data/* ${backup_tmp} || true

new: make_backup
	cp tpl/new.lua data/config.lua


.phony: install make_dirs backup new 

install:
	apt install lua5.3 luarocks liblua5.3-dev
	luarocks install xavante
	luarocks install wsapi-xavante
	luarocks install restserver
