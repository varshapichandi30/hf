At Host ***
helm install ca ./hlf-ca -n cas -f ./prod_example/helm_values/ca.yaml --set adminUsername=admin,adminPassword=admin-pw
export CA_POD=$(kubectl get pods --namespace cas -l "app=hlf-ca,release=ca" -o jsonpath="{.items[0].metada
ta.name}")

Login to CA **************************************
kubectl exec -n cas --stdin --tty   $CA_POD -- sh

Admin ***
fabric-ca-client enroll -d -u http://admin:admin-pw@localhost:7054

Ord MSP ***
fabric-ca-client register --id.name ord-admin --id.secret OrdAdm1nPW --id.attrs 'admin=true:ecert'
FABRIC_CA_CLIENT_HOME=./config fabric-ca-client enroll -u http://ord-admin:OrdAdm1nPW@localhost:7054 -M ./OrdererMSP
mkdir -p ./config/OrdererMSP/admincerts
cp ./config/OrdererMSP/signcerts/* ./config/OrdererMSP/admincerts

Peer MSP ***
fabric-ca-client register --id.name peer-admin --id.secret PeerAdm1nPW --id.attrs 'admin=true:ecert'
FABRIC_CA_CLIENT_HOME=./config fabric-ca-client enroll -u http://peer-admin:PeerAdm1nPW@localhost:7054 -M ./PeerMSP
mkdir -p ./config/PeerMSP/admincerts
cp ./config/PeerMSP/signcerts/* ./config/PeerMSP/admincerts
Log Out from CA ***********************************

At Host **************
kubectl cp $CA_POD:/config ./config -n cas

Ord Admin***********
ORG_CERT=$(ls ./config/OrdererMSP/admincerts/cert.pem)
kubectl create secret generic -n orderers hlf--ord-admincert --from-file=cert.pem=$ORG_CERT
ORG_KEY=$(ls ./config/OrdererMSP/keystore/*_sk)
kubectl create secret generic -n orderers hlf--ord-adminkey --from-file=key.pem=$ORG_KEY
CA_CERT=$(ls ./config/OrdererMSP/cacerts/*.pem)
kubectl create secret generic -n orderers hlf--ord-ca-cert --from-file=cacert.pem=$CA_CERT

Peer Admin ***********
ORG_CERT=$(ls ./config/PeerMSP/admincerts/cert.pem)
kubectl create secret generic -n peers hlf--peer-admincert --from-file=cert.pem=$ORG_CERT
ORG_KEY=$(ls ./config/PeerMSP/keystore/*_sk)
kubectl create secret generic -n peers hlf--peer-adminkey --from-file=key.pem=$ORG_KEY
CA_CERT=$(ls ./config/PeerMSP/cacerts/*.pem)
kubectl create secret generic -n peers hlf--peer-ca-cert --from-file=cacert.pem=$CA_CERT


Genesis and Channel ***********
cd ./config
configtxgen -profile OrdererGenesis -outputBlock ./genesis.block -channelID system-channel
configtxgen -profile MyChannel -channelID mychannel -outputCreateChannelTx ./mychannel.tx

kubectl create secret generic -n orderers hlf--genesis --from-file=genesis.block
kubectl create secret generic -n peers hlf--channel --from-file=mychannel.tx

ORD- Login to CA **************************************
kubectl exec -n cas --stdin --tty   $CA_POD -- sh
export NUM=1

fabric-ca-client register --id.name ord${NUM} --id.secret ord${NUM}_pw --id.type orderer
FABRIC_CA_CLIENT_HOME=./config fabric-ca-client enroll -d -u http://ord${NUM}:ord${NUM}_pw@$localhost:7054 -M ord${NUM}_MSP
Log out of CA ****************************

orderer *****************
NODE_CERT=$(ls ./config/ord${NUM}_MSP/signcerts/*.pem)
kubectl create secret generic -n orderers hlf--ord${NUM}-idcert --from-file=cert.pem=${NODE_CERT}

NODE_KEY=$(ls ./config/ord${NUM}_MSP/keystore/*_sk)
kubectl create secret generic -n orderers hlf--ord${NUM}-idkey --from-file=key.pem=${NODE_KEY}

helm install ord${NUM} ./hlf-ca  -n orderers -f ./prod_example/helm_values/ord${NUM}.yaml
export ORD_POD=$(kubectl get pods --namespace orderers -l "app=hlf-ord,release=ord1" -o jsonpath="{.items[0].metadata.name}")

kubectl cp  ./config/ord1_MSP/signcerts $ORD_POD:/var/hyperledger/msp -n orderers
kubectl cp  ./config/ord1_MSP/cacerts $ORD_POD:/var/hyperledger/msp -n orderers
kubectl cp  ./config/ord1_MSP/keystore $ORD_POD:/var/hyperledger/msp -n orderers

kubectl logs -n orderers $ORD_POD 
orderer end*****************

couchdb node *****************************
helm install cdb-peer${NUM} ./hlf-couchdb -n peers -f ./prod_example/helm_values/cdb-peer${NUM}.yaml
export CDB_POD=$(kubectl get pods --namespace peers -l "app=hlf-couchdb,release=cdb-peer1" -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n peers $CDB_POD | grep 'Apache CouchDB has started on'
couch db end*******************************

Peer-Login to CA **************************************
kubectl exec -n cas --stdin --tty   $CA_POD -- sh
export NUM=1
fabric-ca-client register --id.name peer${NUM} --id.secret peer${NUM}_pw --id.type peer
FABRIC_CA_CLIENT_HOME=./config fabric-ca-client enroll -d -u http://peer${NUM}:peer${NUM}_pw@localhost:7054 -M peer${NUM}_MSP
*****log out to host

peer node**************
--copy the files
kubectl cp $CA_POD:/config ./config -n cas
NODE_CERT=$(ls ./config/peer${NUM}_MSP/signcerts/*.pem)
kubectl create secret generic -n peers hlf--peer${NUM}-idcert --from-file=cert.pem=${NODE_CERT}
NODE_KEY=$(ls ./config/peer${NUM}_MSP/keystore/*_sk)
kubectl create secret generic -n peers hlf--peer${NUM}-idkey --from-file=key.pem=${NODE_KEY}

helm install peer${NUM} ./hlf-peer -n peers -f ./prod_example/helm_values/peer${NUM}.yaml
export PEER_POD=$(kubectl get pods --namespace peers -l "app=hlf-peer,release=peer1" -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n peers $PEER_POD | grep 'Starting peer'
peer node end********

Login to peer pod **************
kubectl exec -n peers --stdin --tty   $PEER_POD -- bin/bash
CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin_msp/
peer channel create -o ord1-hlf-ord.orderers.svc.cluster.local:7050 -c mychannel -f /hl_config/channel/hlf--channel/mychannel.tx
peer channel fetch config /var/hyperledger/mychannel.block -c mychannel -o ord1-hlf-ord.orderers.svc.cluster.local:7050
Logout of peer pod **************


Troubleshooting
Logs
helm uninstall ord1 -n orderers

