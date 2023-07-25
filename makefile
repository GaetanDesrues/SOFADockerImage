all: stop build run

build:
	# docker build -t sofa:23.06 --no-cache .
	docker build -t sofa:23.06 .

run:
	docker run -it --name ct_sofa:23.06 sofa:23.06

stop:
	-docker stop ct_sofa:23.06
	-docker rm ct_sofa:23.06
	-docker rmi sofa:23.06
	# docker image prune

debug: stop build
	docker run -d --name ct_sofa:23.06 sofa:23.06 tail -f /dev/null
	docker exec -it ct_sofa:23.06 bash
	# bash ./runtest.sh
	# python test_scene.py

push:
	docker tag sofa:23.06 gdesrues/sofa:23.06
	docker push gdesrues/sofa:23.06
