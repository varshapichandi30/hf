
***Set path for binary access
```
PATH=$PATH:../bin
```

***Namespaces
```
***Create namespace
kubectl create namespace cas
kubectl create namespace orderers
kubectl create namespace peers
```

***Setup Ca server
```
helm install ca ./charts/hlf-ca -n cas -f ./prod_example/helm_values/ca.yaml --set adminUsername=admin,adminPassword=admin-pw
export CA_POD=$(kubectl get pods --namespace cas -l "app=hlf-ca,release=ca" -o jsonpath="{.items[0].metadata.name}")
```

***Login to CA server
```
kubectl exec -n cas --stdin --tty   $CA_POD -- sh

***Enroll admin
fabric-ca-client enroll -d -u http://admin:admin-pw@localhost:7054

***Register ord admin
fabric-ca-client register --id.name ord-admin --id.secret OrdAdm1nPW --id.attrs 'admin=true:ecert'

***Enroll ord admin
FABRIC_CA_CLIENT_HOME=./config fabric-ca-client enroll -u http://ord-admin:OrdAdm1nPW@localhost:7054 -M ./OrdererMSP
mkdir -p ./config/OrdererMSP/admincerts
cp ./config/OrdererMSP/signcerts/* ./config/OrdererMSP/admincerts

***Register peer admin
fabric-ca-client register --id.name peer-admin --id.secret PeerAdm1nPW --id.attrs 'admin=true:ecert'

***Enroll peer admin
FABRIC_CA_CLIENT_HOME=./config fabric-ca-client enroll -u http://peer-admin:PeerAdm1nPW@localhost:7054 -M ./PeerMSP
mkdir -p ./config/PeerMSP/admincerts
cp ./config/PeerMSP/signcerts/* ./config/PeerMSP/admincerts

exit
```
```
***Copy credentials to host config folder
kubectl cp $CA_POD:/config ./build/crypto-config -n cas

***Create orderer secrets
ORG_CERT=$(ls ./build/crypto-config/OrdererMSP/admincerts/cert.pem)
kubectl create secret generic -n orderers hlf--ord-admincert --from-file=cert.pem=$ORG_CERT
ORG_KEY=$(ls ./build/crypto-config/OrdererMSP/keystore/*_sk)
kubectl create secret generic -n orderers hlf--ord-adminkey --from-file=key.pem=$ORG_KEY
CA_CERT=$(ls ./build/crypto-config/OrdererMSP/cacerts/*.pem)
kubectl create secret generic -n orderers hlf--ord-ca-cert --from-file=cacert.pem=$CA_CERT

***Create peer secrets
ORG_CERT=$(ls ./build/crypto-config/PeerMSP/admincerts/cert.pem)
kubectl create secret generic -n peers hlf--peer-admincert --from-file=cert.pem=$ORG_CERT
ORG_KEY=$(ls ./build/crypto-config/PeerMSP/keystore/*_sk)
kubectl create secret generic -n peers hlf--peer-adminkey --from-file=key.pem=$ORG_KEY
CA_CERT=$(ls ./build/crypto-config/PeerMSP/cacerts/*.pem)
kubectl create secret generic -n peers hlf--peer-ca-cert --from-file=cacert.pem=$CA_CERT
```

***Genesis and Channel
```
configtxgen -profile OrdererGenesis -outputBlock ./genesis.block -channelID system-channel
configtxgen -profile MyChannel -channelID mychannel -outputCreateChannelTx ./mychannel.tx

kubectl create secret generic -n orderers hlf--genesis --from-file=genesis.block
kubectl create secret generic -n peers hlf--channel --from-file=mychannel.tx
```

***Login to CA
```
kubectl exec -n cas --stdin --tty   $CA_POD -- sh
export NUM=1

***Register ord1
fabric-ca-client register --id.name ord${NUM} --id.secret ord${NUM}_pw --id.type orderer
***Enroll ord1
FABRIC_CA_CLIENT_HOME=./config fabric-ca-client enroll -d -u http://ord${NUM}:ord${NUM}_pw@$localhost:7054 -M ord${NUM}_MSP

exit
```

***Copy certificates to host machine
```
kubectl cp $CA_POD:/config ./build/crypto-config/ -n cas
export NUM=1

***Create secrets
NODE_CERT=$(ls ./build/crypto-config/ord${NUM}_MSP/signcerts/*.pem)
kubectl create secret generic -n orderers hlf--ord${NUM}-idcert --from-file=cert.pem=${NODE_CERT}

NODE_KEY=$(ls ./build/crypto-config/ord${NUM}_MSP/keystore/*_sk)
kubectl create secret generic -n orderers hlf--ord${NUM}-idkey --from-file=key.pem=${NODE_KEY}

****Install ord1
helm install ord${NUM} ./charts/hlf-ord  -n orderers -f ./prod_example/helm_values/ord${NUM}.yaml
export ORD_POD=$(kubectl get pods --namespace orderers -l "app=hlf-ord,release=ord1" -o jsonpath="{.items[0].metadata.name}")

***Copy certificates to MSP folder - It is a bug in the chart so we have to manually copy this
kubectl cp  ./build/crypto-config/ord1_MSP/signcerts $ORD_POD:/var/hyperledger/msp -n orderers
kubectl cp  ./build/crypto-config/ord1_MSP/cacerts $ORD_POD:/var/hyperledger/msp -n orderers
kubectl cp  ./build/crypto-config/ord1_MSP/keystore $ORD_POD:/var/hyperledger/msp -n orderers

kubectl logs -n orderers $ORD_POD 
```

**CouchDB install
```
helm install cdb-peer${NUM} ./charts/hlf-couchdb -n peers -f ./prod_example/helm_values/cdb-peer${NUM}.yaml
export CDB_POD=$(kubectl get pods --namespace peers -l "app=hlf-couchdb,release=cdb-peer1" -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n peers $CDB_POD | grep 'Apache CouchDB has started on'
````

***Login to CA for peer certificates
```
kubectl exec -n cas --stdin --tty   $CA_POD -- sh
export NUM=1
fabric-ca-client register --id.name peer${NUM} --id.secret peer${NUM}_pw --id.type peer
FABRIC_CA_CLIENT_HOME=./config fabric-ca-client enroll -d -u http://peer${NUM}:peer${NUM}_pw@localhost:7054 -M peer${NUM}_MSP

exit
```

*** Copy peer certificates to host
```
kubectl cp $CA_POD:/config ./build/crypto-config/ -n cas
NODE_CERT=$(ls ./build/crypto-config/peer${NUM}_MSP/signcerts/*.pem)
kubectl create secret generic -n peers hlf--peer${NUM}-idcert --from-file=cert.pem=${NODE_CERT}
NODE_KEY=$(ls ./build/crypto-config/peer${NUM}_MSP/keystore/*_sk)
kubectl create secret generic -n peers hlf--peer${NUM}-idkey --from-file=key.pem=${NODE_KEY}
```

***Install peer helm chart
```
helm install peer${NUM} ./charts/hlf-peer -n peers -f ./prod_example/helm_values/peer${NUM}.yaml
export PEER_POD=$(kubectl get pods --namespace peers -l "app=hlf-peer,release=peer1" -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n peers $PEER_POD | grep 'Starting peer'
```

***Join channel in CLI
```
helm install peer${NUM}-cli ./charts/hlf-peer-cli -n peers -f ./prod_example/helm_values/peer${NUM}-cli.yaml
kubectl exec -n peers --stdin --tty   $POD_NAME -- bin/bash

FABRIC_CFG_PATH=/etc/hyperledger/fabric/
CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin_msp/

#Create channel
peer channel create -o ord1-hlf-ord.orderers.svc.cluster.local:7050 -c mychannel -f /hl_config/channel/hlf--channel/mychannel.tx

peer channel fetch config mychannel.block -c mychannel -o ord1-hlf-ord.orderers.svc.cluster.local:7050
peer channel join -b mychannel.block

peer chaincode query -C mychannel -n sacc -c '{"Args":["get","name"]}'
peer chaincode instantiate -o ord1-hlf-ord.orderers.svc.cluster.local:7050 -n sacc -v 1.0 -c '{"Args":["key1","value1"]}' -C mychannel
peer chaincode invoke -o ord1-hlf-ord.orderers.svc.cluster.local:7050 --peerAddresses peer1-hlf-peer.peers.svc.cluster.local:7051 -C mychannel -n sacc -c '{"Args":["set","name","Brahma"]}'
```


***Troubleshooting
```
Check Logs of pod
***Uninstall helm chart, example for orderer
helm uninstall ord1 -n orderers
```
