//
//  ConnectivityManager.swift
//  MCSession-P2P
//
//  Created by a on 11/12/25.
//

import MultipeerConnectivity
import Combine

class ConnectivityManager: NSObject, ObservableObject {
    @Published var connectedPeers: [MCPeerID] = []
    @Published var connectedDevices: [Device] = []
    @Published var isShowSheet = false
    @Published var openMessage = ""
    
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    private let device = Device(modelName: UIDevice.current.name)
    private let myPeerID: MCPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let serviceType: String = "my-service"
    
    override init() {
        super.init()
        configureSession()
    }
    
    // 세션 설정
    func configureSession() {
        self.session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .none
        )
        session.delegate = self
        
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: nil,
            serviceType: serviceType
        )
        advertiser.delegate = self
        
        self.browser = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: serviceType
        )
        browser.delegate = self
    }
    
    func startSession() {
        print(#function)
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    func stopSession() {
        print(#function)
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        
        connectedPeers.removeAll()
        connectedDevices.removeAll()
    }
}

extension ConnectivityManager {
    @MainActor
    func connectDevice() {
        do {
            try session.send("\(device.modelName) Open connected device".data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            isShowSheet = true
        } catch {
            
        }
    }
    
    @MainActor
    func openConnectedDevice(_ message: String) {
        isShowSheet = true
        openMessage = message
    }
}

// MARK: - MCSessionDelegate

extension ConnectivityManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .connected {
            print("Connected")
            DispatchQueue.main.async {
                self.connectedPeers = session.connectedPeers
            }
        } else if state == .connecting {
            print("Connecting...")
        } else {
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            if let message = String(data: data, encoding: .utf8) {
                openConnectedDevice(message)
            }
        } catch {
            
        }
        print(#function)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print(#function)
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print(#function)
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        print(#function)
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension ConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        do {
            if let data = context {
                let device = try data.decode(Device.self)
                connectedDevices.append(device)
            }
        } catch {
            
        }
        invitationHandler(true, session)
        print(#function)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension ConnectivityManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        do {
            let deviceData = try device.encode()
            browser.invitePeer(peerID, to: session, withContext: deviceData, timeout: 30)
        } catch {
            
        }
        print(#function)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("\(peerID) 와 연결해제")
        session.cancelConnectPeer(peerID)
        connectedPeers = session.connectedPeers
    }
}

extension Data {
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: self)
    }
}

extension Encodable {
    func encode() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
}
