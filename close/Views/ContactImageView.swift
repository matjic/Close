//
//  ContactImageView.swift
//  close
//
//  Created by Mathew Jacob on 10/12/25.
//

import SwiftUI
import Contacts

struct ContactImageView: View {
    let contactIdentifier: String?
    let size: CGFloat
    
    @State private var image: UIImage?
    
    init(contactIdentifier: String?, size: CGFloat = 40) {
        self.contactIdentifier = contactIdentifier
        self.size = size
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.gray.opacity(0.3))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task {
            await loadContactImage()
        }
    }
    
    private func loadContactImage() async {
        guard let identifier = contactIdentifier else { return }
        
        // Fetch image on background thread
        let fetchedImage = await Task.detached {
            let store = CNContactStore()
            let keys = [CNContactImageDataKey, CNContactImageDataAvailableKey] as [CNKeyDescriptor]
            
            do {
                let contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keys)
                
                if contact.imageDataAvailable, let imageData = contact.imageData {
                    return UIImage(data: imageData)
                }
            } catch {
                print("Failed to fetch contact image: \(error)")
            }
            
            return nil
        }.value
        
        await MainActor.run {
            self.image = fetchedImage
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ContactImageView(contactIdentifier: nil, size: 60)
        ContactImageView(contactIdentifier: nil, size: 100)
    }
}

