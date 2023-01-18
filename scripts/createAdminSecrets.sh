#Create orderer secrets
ORG_CERT=$(ls ./build/crypto-config/OrdererMSP/admincerts/cert.pem)
kubectl create secret generic -n orderers hlf--ord-admincert --from-file=cert.pem=$ORG_CERT
ORG_KEY=$(ls ./build/crypto-config/OrdererMSP/keystore/*_sk)
kubectl create secret generic -n orderers hlf--ord-adminkey --from-file=key.pem=$ORG_KEY
CA_CERT=$(ls ./build/crypto-config/OrdererMSP/cacerts/*.pem)
kubectl create secret generic -n orderers hlf--ord-ca-cert --from-file=cacert.pem=$CA_CERT

#Create peer secrets
ORG_CERT=$(ls ./build/crypto-config/PeerMSP/admincerts/cert.pem)
kubectl create secret generic -n peers hlf--peer-admincert --from-file=cert.pem=$ORG_CERT
ORG_KEY=$(ls ./build/crypto-config/PeerMSP/keystore/*_sk)
kubectl create secret generic -n peers hlf--peer-adminkey --from-file=key.pem=$ORG_KEY
CA_CERT=$(ls ./build/crypto-config/PeerMSP/cacerts/*.pem)
kubectl create secret generic -n peers hlf--peer-ca-cert --from-file=cacert.pem=$CA_CERT
