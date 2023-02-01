# Remove crypto materials if any
```
rm -rf ./build/crypto-config/
```
# Set path for binary access
```
PATH=$PATH:./bin
```
# Create Namespaces
```
kubectl apply -f ./releases/namespaces.yaml
```
# Setup Ca server
```
helm install ca ./charts/hlf-ca -n cas -f ./releases/helm_values/ca.yaml --set adminUsername=admin,adminPassword=admin-pw
export CA_POD=$(kubectl get pods --namespace cas -l "app=hlf-ca,release=ca" -o jsonpath="{.items[0].metadata.name}")
```

# Enroll Orderer and peer admin and generate secrets
```
kubectl cp ./scripts/enrollAdmins.sh $CA_POD:/ -n cas
kubectl exec -n cas --stdin --tty   $CA_POD -- sh
chmod 777 ./enrollAdmins.sh
./enrollAdmins.sh
exit
#Copy credentials to host config folder
kubectl cp $CA_POD:/config ./build/crypto-config -n cas
#Create secrets for Admins
chmod 777 ./scripts/createAdminSecrets.sh
./scripts/createAdminSecrets.sh

```
# Enroll orderer node and generate tls
```
kubectl cp ./scripts/enrollOrderer.sh $CA_POD:/ -n cas
#Login to CA
kubectl exec -n cas --stdin --tty   $CA_POD -- sh
#Enroll ord1 certs and tls
chmod 777 ./enrollOrderer.sh
./enrollOrderer.sh
exit
#Copy certificates to host machine
kubectl cp $CA_POD:/config ./build/crypto-config/ -n cas
#Create orderer secrets
chmod 777 ./scripts/createOrdererSecrets.sh
./scripts/createOrdererSecrets.sh
```

# Enroll peer node and generate tls
```
#Copy enroll scripts to CA
kubectl cp ./scripts/enrollPeer.sh $CA_POD:/ -n cas
#Login to CA & Enroll peer certs and tls
kubectl exec -n cas --stdin --tty   $CA_POD -- sh
chmod 777 ./enrollPeer.sh
./enrollPeer.sh
exit
#Copy peer certificates to host
kubectl cp $CA_POD:/config ./build/crypto-config/ -n cas
#Create peer secrets
chmod 777 ./scripts/createPeerSecrets.sh
./scripts/createPeerSecrets.sh

```
# Create Genesis and channel tx & secrets
```
chmod 777 ./scripts/createChannelSecrets.sh
./scripts/createChannelSecrets.sh
```

# Bring up orderer node
```
NUM=1
helm install ord${NUM} ./charts/hlf-ord  -n orderers -f ./releases/helm_values/ord${NUM}.yaml
export ORD_POD=$(kubectl get pods --namespace orderers -l "app=hlf-ord,release=ord1" -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n orderers $ORD_POD 
```

# Bring up CouchDB node
```
NUM=1
helm install cdb-peer${NUM} ./charts/hlf-couchdb -n peers -f ./releases/helm_values/cdb-peer${NUM}.yaml
export CDB_POD=$(kubectl get pods --namespace peers -l "app=hlf-couchdb,release=cdb-peer1" -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n peers $CDB_POD | grep 'Apache CouchDB has started on'
```

# Bring up peer node
```
helm install peer${NUM} ./charts/hlf-peer -n peers -f ./releases/helm_values/peer${NUM}.yaml
export PEER_POD=$(kubectl get pods --namespace peers -l "app=hlf-peer,release=peer1" -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n peers $PEER_POD | grep 'Starting peer'
```

# Start a peer and join channel 
```
helm install peer${NUM}-cli ./charts/hlf-peer-cli -n peers -f ./releases/helm_values/peer${NUM}-cli.yaml
export CLI_POD=$(kubectl get pods --namespace peers -l "app=hlf-peer,release=peer1-cli" -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n peers --stdin --tty $CLI_POD  -- sh

FABRIC_CFG_PATH=/etc/hyperledger/fabric/
CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin_msp/

#Create channel
peer channel create -o ord1-hlf-ord.orderers.svc.cluster.local:7050 -c mychannel -f /hl_config/channel/hlf--channel/mychannel.tx --tls --cafile /var/hyperledger/tls/server/cert/key.pem

#Join channel
peer channel fetch config mychannel.block -c mychannel -o ord1-hlf-ord.orderers.svc.cluster.local:7050 --tls --cafile /var/hyperledger/tls/server/cert/key.pem
peer channel join -b mychannel.block



export ORDERER_CA=/var/hyperledger/tls/server/cert/key.pem
export ORDERER_CONTAINER=ord1-hlf-ord.orderers.svc.cluster.local:7050

peer lifecycle chaincode approveformyorg -o $ORDERER_CONTAINER --tls --cafile $ORDERER_CA --channelID mychannel --name marbles --version 1.0 --package-id $ID --sequence 1

peer lifecycle chaincode commit -o  $ORDERER_CONTAINER --tls --cafile $ORDERER_CA --channelID mychannel --name sacc --version 1.0 --sequence 1 --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE

peer chaincode invoke -o  $ORDERER_CONTAINER --tls --cafile $ORDERER_CA --channelID mychannel --name sacc --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE -c '{"function":"set","args":["name","Brahma"]}'


```



Remove Setup
```
NUM=1
helm uninstall ca -n cas
helm uninstall ord${NUM} -n orderers
helm uninstall peer${NUM} -n peers
helm uninstall cdb-peer${NUM} -n peers
helm uninstall peer${NUM}-cli -n peers
kubectl delete secrets --all -n orderers
kubectl delete secrets --all -n peers
kubectl delete secrets --all -n cas
kubectl delete ns peers orderers cas
```

In the fabcar folder :
create fabcar folder
create fabcar.go
go mod init github.com/hyperledger/fabric-samples/chaincode/fabcar/go
go mod vendor


kubectl cp  /home/lohith/hf/fabcar peer1-cli-hlf-peer-6d7f56bc69-n772j:/opt/gopath/src/github.com/hyperledger/fabric/peer/fabcar -n peers
peer lifecycle chaincode package basic.tar.gz -p /opt/gopath/src/github.com/hyperledger/fabric/peer/fabcar --label basic_1.0
peer lifecycle chaincode install basic.tar.gz
peer lifecycle chaincode queryinstalled
export ORDERER_CA=/var/hyperledger/tls/server/cert/key.pem
export ORDERER_CONTAINER=ord1-hlf-ord.orderers.svc.cluster.local:7050
export ID=basic_1.0:d14a94f52067abe5830fafecf4a9ac236fb5f7298ca1f5c4a86b9e44b9d1cc5e 
peer lifecycle chaincode approveformyorg -o $ORDERER_CONTAINER --tls --cafile $ORDERER_CA --channelID mychannel --name basic --version 1.0 --package-id $ID --sequence 1
peer lifecycle chaincode commit -o  $ORDERER_CONTAINER --tls --cafile $ORDERER_CA --channelID mychannel --name basic --version 1.0 --sequence 1 --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE
peer chaincode invoke -o  $ORDERER_CONTAINER --tls --cafile $ORDERER_CA --channelID mychannel --name basic --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE -c '{"function":"InitLedger","args":[]}'
peer chaincode query -C mychannel -n basic -c '{"Args":["QueryAllCars"]}'
peer chaincode invoke -o  $ORDERER_CONTAINER --tls --cafile $ORDERER_CA --channelID mychannel --name basic --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE -c '{"function":"CreateCar","args":["dddd","ffff","ggg","ttt","lll"]}'
peer chaincode invoke -o  $ORDERER_CONTAINER --tls --cafile $ORDERER_CA --channelID mychannel --name basic --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE -c '{"function":"QueryCar","args":["dddd"]}'

External Chaincode :
kubectl cp  /home/lohith/hf/chaincode peer1-cli-hlf-peer-7f77c4968b-58mmj:/opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode -n peers
peer lifecycle chaincode install chaincode/chaincode.tgz
peer lifecycle chaincode queryinstalled
export ORDERER_CA=/var/hyperledger/tls/server/cert/key.pem
export ORDERER_CONTAINER=ord1-hlf-ord.orderers.svc.cluster.local:7050
export ID=marbles:1213c935da0ba631d0cc36e27d83b0685afc71297933a7101362cd6f92daf7d1
peer lifecycle chaincode approveformyorg -o $ORDERER_CONTAINER --tls --cafile $ORDERER_CA --channelID mychannel --name marbles --version 1.0 --package-id $ID --sequence 3 --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE
peer lifecycle chaincode commit -o  $ORDERER_CONTAINER --tls --cafile $ORDERER_CA --channelID mychannel --name marbles --version 1.0 --sequence 3 --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE
peer chaincode invoke -o  $ORDERER_CONTAINER --tls true --cafile $ORDERER_CA -C mychannel -n marbles --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE -c '{"Args":["initMarble","marble1","blue","35","tom"]}' --waitForEvent
peer chaincode query -C mychannel -n marbles -c '{"Args":["readMarble","marble1"]}'

kubectl cp peer1-cli-hlf-peer-6d7f56bc69-n772j:/etc/hyperledger/fabric/core.yaml /home/lohith/hf/core.yaml -n peers
