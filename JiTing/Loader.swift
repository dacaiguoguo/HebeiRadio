//
//  Loader.swift
//  JiTing
//
//  Created by yanguo sun on 2022/3/11.
//

import Foundation
import UIKit


func load<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

enum LoaderError: Error {
    case invalidServerResponse
    case unsupportedImage
}

// Fetch photo with async/await
func fetchPhoto(url: URL) async throws -> UIImage {
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
              throw LoaderError.invalidServerResponse
          }

    guard let image = UIImage(data: data) else {
        throw LoaderError.unsupportedImage
    }

    return image
}
