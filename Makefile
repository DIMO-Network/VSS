#
# Makefile to generate specifications
#

.PHONY: clean all mandatory_targets json franca yaml csv ddsidl tests binary protobuf ttl graphql ocf c overlays id jsonschema

all: clean mandatory_targets optional_targets

# All mandatory targets that shall be built and pass on each pull request for
# vehicle-signal-specification or vss-tools
mandatory_targets: clean json json-noexpand franca yaml binary csv graphql ddsidl id jsonschema overlays tests

# Additional targets that shall be built by travis, but where it is not mandatory
# that the builds shall pass.
# This is typically intended for less maintainted tools that are allowed to break
# from time to time
# Can be run from e.g. travis with "make -k optional_targets || true" to continue
# even if errors occur and not do not halt travis build if errors occur
optional_targets: clean protobuf ttl

TOOLSDIR?=./vss-tools
VENV_NAME?=vss-tools
VENV_PATH?=.venv/${VENV_NAME}
GIT_COMMIT := $(shell git rev-parse --short HEAD)

VSS_VERSION := $(shell cat VERSION)-$(GIT_COMMIT)

json:
	${TOOLSDIR}/vspec2json.py -I ./spec -o overlays/DIMO/dimo.vspec --uuid -u ./spec/units.yaml ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION).json

json-noexpand:
	${TOOLSDIR}/vspec2json.py -I ./spec -o overlays/DIMO/dimo.vspec --uuid -u ./spec/units.yaml --no-expand ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION)_noexpand.json

jsonschema:
	${TOOLSDIR}/vspec2jsonschema.py -I ./spec -o overlays/DIMO/dimo.vspec --uuid -u ./spec/units.yaml ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION).jsonschema

franca:
	${TOOLSDIR}/vspec2franca.py -v $(VSS_VERSION)  -I ./spec -o overlays/DIMO/dimo.vspec --uuid -u ./spec/units.yaml ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION).fidl

yaml:
	${TOOLSDIR}/vspec2yaml.py -I ./spec -o overlays/DIMO/dimo.vspec --uuid -u ./spec/units.yaml ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION).yaml

csv:
	python ${TOOLSDIR}/vspec2csv.py -I ./spec -vt overlays/DIMO/types.vspec -o overlays/DIMO/dimo.vspec --uuid -u ./spec/units.yaml ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION).csv

ddsidl:
	${TOOLSDIR}/vspec2ddsidl.py -I ./spec -o overlays/DIMO/dimo.vspec --uuid -u ./spec/units.yaml ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION).idl

# Verifies that supported overlay combinations are syntactically correct.
overlays:
	${TOOLSDIR}/vspec2json.py -I ./spec -o overlays/DIMO/dimo.vspec --uuid -u ./spec/units.yaml -o overlays/profiles/motorbike.vspec ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION)_motorbike.json
	${TOOLSDIR}/vspec2json.py -I ./spec -o overlays/DIMO/dimo.vspec --uuid -u ./spec/units.yaml -o overlays/extensions/dual_wiper_systems.vspec ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION)_dualwiper.json

tests:
	PYTHONPATH=${TOOLSDIR} pytest

binary:
	gcc -shared -o ${TOOLSDIR}/binary/binarytool.so -fPIC ${TOOLSDIR}/binary/binarytool.c
	${TOOLSDIR}/vspec2binary.py --uuid -u ./spec/units.yaml ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION).binary

protobuf:
	${TOOLSDIR}/vspec2protobuf.py  -I ./spec -o overlays/DIMO/dimo.vspec -u ./spec/units.yaml ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION).proto

graphql:
	${TOOLSDIR}/vspec2graphql.py -I ./spec -o overlays/DIMO/dimo.vspec --uuid -u ./spec/units.yaml ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION).graphql.ts

ttl:
	${TOOLSDIR}/contrib/vspec2ttl/vspec2ttl.py -I ./spec -o overlays/DIMO/dimo.vspec -u ./spec/units.yaml ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION).ttl

id:
	${TOOLSDIR}/vspec2id.py -I ./spec -o overlays/DIMO/dimo.vspec --uuid -u ./spec/units.yaml ./spec/VehicleSignalSpecification.vspec vss_rel_$(VSS_VERSION).vspec

venv:
	@echo "Checking if virtual environment $(VENV_NAME) exists..."
	@if [ -d "$(VENV_PATH)" ]; then \
		echo "Virtual environment exists."; \
		echo "Activate  With \`. $(VENV_PATH)/bin/activate\`"; \
	else \
		echo "Virtual environment does not exist. Creating..."; \
		python3 -m venv $(VENV_PATH); \
		. $(VENV_PATH)/bin/activate; \
		pip install ${TOOLSDIR}; \
		echo "Virtual environment created."; \
		echo "Activate  With \`. $(VENV_PATH)/bin/activate\`"; \
	fi

clean:
	rm -f ${TOOLSDIR}/binary/binarytool.so
	rm -f vss_rel_*
