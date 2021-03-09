//
//  OgpHtmlClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/04.
//

import Foundation
import UIKit
import CodableURL

public class OgpHtmlClient {
    let baseUrl: String = "https://serverless-prd.rocketfor.band/custom_ogp_html"
    
    func getOgpUrl(imageUrl: String, title: String) -> String {
        let urlString = "\(baseUrl)?ogp_url=\(imageUrl)&title=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
        return urlString
    }
    
    init() {
    }
}
