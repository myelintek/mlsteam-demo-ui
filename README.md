# mlsteam-demo-ui

## docker image usage
Mapping host port 8080 to container port
```
docker run -d -p 8080:80 myelintek/demo-service:v1.0 
```
Test on [http://<host_ip>:8080](http://<host_ip>:8080)

## build docker iamge
```
cd mlsteam-demo-ui
docker build -t <tag> .
```

## Manually build and setup
``` 
cd mlsteam-demo-ui/ui
npm install
npm build
```
ouptut are in cd mlsteam-demo-ui/ui/dist
copy to app folder
```
cp -r mlsteam-demo-ui/ui/dist mlsteam-deom-ui/app/static
```
## Run service
```
cd mlsteam-deom-ui/app
python main.py
```
server will run in 80 port

