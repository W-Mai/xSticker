//
//  AuxTool.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/16.
//

import Foundation
import UIKit
import SwiftUI

struct NavigationConfigurator: UIViewControllerRepresentable {
    var configure: (UINavigationController) -> Void = { _ in }

    func makeUIViewController(context: UIViewControllerRepresentableContext<NavigationConfigurator>) -> UIViewController {
        UIViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<NavigationConfigurator>) {
        if let nc = uiViewController.navigationController {
            self.configure(nc)
        }
    }
}

struct MyTextField: UIViewRepresentable {
    typealias UIViewType = UITextField
    
    @Binding var text: String
    var didFinished: ()->()
    
    func makeUIView(context: Context) -> UIViewType {
        let textField = UIViewType()
        
        textField.clearButtonMode = .always
        textField.returnKeyType = .done
        
        textField.delegate = context.coordinator
        return textField
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.text = text
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var didFinished: ()->()
        
        init(text: Binding<String>, didFinished: @escaping ()->()) {
            self.text = text
            self.didFinished = didFinished
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            text.wrappedValue = textField.text ?? ""
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            didFinished()
            return true
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, didFinished: didFinished)
    }
}

func getVerStr() -> String {
    let info = Bundle.main.infoDictionary!
    let version = "Verison \(info["CFBundleShortVersionString"]!) build \(info["CFBundleVersion"]!)"
    
    return version
}


func L(_ str: String) -> String {
    return NSLocalizedString(str, comment: "")
}

