
# Build
```
docker build -t node-cognixus:1.0 .
```

# Run
```
docker run -d -p 5000:5000 -e PORT=5000 node-cognixus:1.0
```

# Push to dockerhub
- repo have to be created in docker hub first
```
docker tag node-cognixus:1.0 kacangcian/node-cognixus:1.0
docker login --username=kacangcian
docker push kacangcian/node-cognixus:1.0
```

# minikube
- minikube on 1 cpu node
```
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
sudo rpm -Uvh minikube-latest.x86_64.rpm
minikube start --extra-config=kubeadm.ignore-preflight-errors=NumCPU --force --cpus 1
minikube addons enable ingress
alias kubectl="minikube kubectl --"
kubectl apply -f node-cognixus/node-replica-set.yml 
kubectl apply -f node-cognixus/node-service.yml
kubectl apply -f node-cognixus/node-ingress.yml
```
