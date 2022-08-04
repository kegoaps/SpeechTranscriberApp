//
//  ContentView.swift
//  SpeechTranscriber
//
//  Created by Kego on 04/08/22.
//

import SwiftUI
import Speech

struct ContentView: View {
    
    @State private var presentImporter = false
    @State private var path = URL(string: "")
    
    @State private var transcript = ""
    
    @State private var document: MessageDocument = MessageDocument(message: "")
    @State private var presentExporter: Bool = false
    @State private var showingAlert: Bool = false
    
    var body: some View {
        VStack {
            Button("Select voice memo file") { presentImporter = true }
                .padding(.bottom, 50)
                .fileImporter(isPresented: $presentImporter, allowedContentTypes: [.item]) { result in
                    switch result {
                    case .success(let url):
                        
                        print(url)
                        path = url
                        url.startAccessingSecurityScopedResource()
                        
                    case .failure(let error):
                        print(error)
                    }
                }
            
            Button("Transcribe") { transcribe() }
                .padding(.bottom, 50)
            
            Button("Save to txt file") {
                
                if transcript != "" {
                    document = MessageDocument(message: "\(transcript)")
                    self.presentExporter = true
                }
                
            }
            .padding(.bottom, 50)
            .alert("The transcript file has been successfully saved", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            }
            .fileExporter( isPresented: $presentExporter, document: document, contentType: .plainText, defaultFilename: "transcript") { result in
                if case .success = result {
                    self.showingAlert = true
                }
            }
        }
    }
    
    func transcribe() {
        SFSpeechRecognizer.requestAuthorization {
            authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("You are authorized by user to perform Speech Recognition")
                    transcribeFile(url: path!)
                } else {
                    print("Transcription permission was declined by user")
                }
            }
        }
    }
    
    func transcribeFile(url:URL) {
        guard let myRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "id_ID")) else {
            print("The recognizer is not supported for the current locale")
            return
        }
        
        if !myRecognizer.isAvailable {
            print("The recognizer is not available right now")
            return
        }
        
        let path_to_audio = url
        print(path_to_audio)
        
        let request = SFSpeechURLRecognitionRequest(url: path_to_audio)
        print("About to create recognition task...")
        
        myRecognizer.recognitionTask(with: request) { (result, error) in
            guard let result = result else {
                print("Recognition failed, please check the printed error message")
                print(error!)
                return
            }
            
            if result.isFinal {
                print(result.bestTranscription.formattedString)
                
                transcript = result.bestTranscription.formattedString
            }
        }
    }
}

struct MessageDocument: FileDocument {
    
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var message: String
    
    init(message: String) {
        self.message = message
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        message = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: message.data(using: .utf8)!)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
