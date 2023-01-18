NUM=1
NODE_CERT=$(ls ./build/crypto-config/peer${NUM}_MSP/msp/signcerts/*.pem)
kubectl create secret generic -n peers hlf--peer${NUM}-idcert --from-file=cert.pem=${NODE_CERT}
NODE_KEY=$(ls ./build/crypto-config/peer${NUM}_MSP/msp/keystore/*_sk)
kubectl create secret generic -n peers hlf--peer${NUM}-idkey --from-file=key.pem=${NODE_KEY}

ORG_TLS=$(ls ./build/crypto-config/PeerMSP/tlsca/*.pem)
kubectl create secret generic -n peers hlf--peer-tlsrootcert --from-file=key.pem=${ORG_TLS}


PEER_TLS_CERT=$(ls ./build/crypto-config/peer${NUM}_MSP/tls/signcerts/*.pem)
PEER_TLS_KEY=$(ls ./build/crypto-config/peer${NUM}_MSP/tls/keystore/*_sk)
kubectl create secret generic -n peers hlf--peer${NUM}-tls --from-file=server.crt=${PEER_TLS_CERT} --from-file=server.key=${PEER_TLS_KEY}