//
//  APIKeys.swift
//  TestDrivenAIGenerator
//
//  Created by Cristian Felipe Patiño Rojas on 14/12/24.
//
import Foundation

enum APIKeys {
    static var gemini: String {
        class BundleFinder {}
        let bundle = Bundle(for: BundleFinder.self)
        let path   = bundle.path(forResource: "api_keys", ofType: "plist")!
        let dict   = NSDictionary(contentsOfFile: path) as! [String: Any]
        return dict["gemini"] as! String
    }
}
