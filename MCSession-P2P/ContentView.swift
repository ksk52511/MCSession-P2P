//
//  ContentView.swift
//  MCSession-P2P
//
//  Created by a on 11/12/25.
//

import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @StateObject var connectivityManager = ConnectivityManager()
    @State var isOn = false
    
    var body: some View {
        Form {
            Toggle("Toggle Connection", isOn: $isOn)
            
            Section(header: Text("Nearby Devices")) {
                List(connectivityManager.connectedPeers, id: \.self) { peer in
                    Text(peer.displayName)
                }
            }
            
            Button {
                connectivityManager.connectDevice()
            } label: {
                Text("Connect Device")
            }
        }
        .onChange(of: isOn) { isOn in
            if isOn {
                connectivityManager.startSession()
            } else {
                connectivityManager.stopSession()
            }
        }
        .sheet(isPresented: $connectivityManager.isShowSheet) {
            Form {
                Section(header: VStack {
                    Text("Connected Devices").font(.largeTitle)
                    Text(connectivityManager.openMessage)
                } ) {
                    List(connectivityManager.connectedDevices, id: \.self) { device in
                        Text(device.modelName)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
