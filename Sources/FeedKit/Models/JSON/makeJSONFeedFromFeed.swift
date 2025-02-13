//
//  makeJSONFeedFromFeed.swift
//  
//
//  Created by dex on 14/11/2022.
//

import Foundation

extension JSONFeed {
    public static func makeJSONFeed(from feed: Feed) -> JSONFeed {
        var newFeed = JSONFeed()
        newFeed.version = "https://jsonfeed.org/version/1.1"
        switch feed {
        case .atom(let atomFeed):
            newFeed.title = atomFeed.title
            
            // Links
            for link in atomFeed.links ?? [] {
                // Home page URL
                if link.attributes?.rel == nil || link.attributes?.rel == "alternate" {
                    if let url = URL(string: link.attributes?.href ?? "") {
                        newFeed.homePageURL = url
                    }
                }
                
                // Feed URL
                if link.attributes?.rel == "self" {
                    if let url = URL(string: link.attributes?.href ?? "") {
                        newFeed.feedUrl = url
                    }
                }
                
                // Hub
                if link.attributes?.rel == "hub" {
                    if newFeed.hubs == nil {
                        newFeed.hubs = []
                    }
                    if let url = URL(string: link.attributes?.href ?? "") {
                        newFeed.hubs?.append(JSONFeedHub(url: url))
                    }
                }
            }
            
            // Description
            newFeed.description = atomFeed.subtitle?.value
            
            // Entries
            for item in atomFeed.entries ?? [] {
                var newItem = JSONFeedItem()
                
                newItem.summary = item.summary?.attributes?.type
                newItem.id = item.id
                
                // TO DO: if summary is HTML convert it to Text. Same with title
                newItem.title = item.title
                newItem.summary = item.summary?.value
                
                // Authors
                if let authors = atomFeed.authors {
                    newItem.authors = []
                    for author in authors {
                        newItem.authors?.append(JSONFeedAuthor(name: author.name, url: URL(string: author.uri ?? "")))
                    }
                }
                
                // Attachments
                for link in item.links ?? [] {
                    if link.attributes?.rel == "enclosure" {
                        var newAttachment = JSONFeedAttachment()
                        
                        newAttachment.url = URL(string: link.attributes?.href ?? "")
                        newAttachment.sizeInBytes = link.attributes?.length == nil ? nil : Int(link.attributes!.length!)
                        newAttachment.mimeType = link.attributes?.type
                        
                        if newItem.attachments == nil {
                            newItem.attachments = []
                        }
                        
                        newItem.attachments?.append(newAttachment)
                    }
                }
            }
        case .rss(let rssFeed):
            newFeed.title = rssFeed.title
            newFeed.description = rssFeed.description
            
            // RSS Cloud
            let cloudAttributes = rssFeed.cloud?.attributes
            if let domain = cloudAttributes?.domain {
                var newHub = JSONFeedHub()
                var url = domain
                if let port = cloudAttributes?.port {
                    url += ":" + String(port)
                }
                if let path = cloudAttributes?.path {
                    url += path
                }
                
                newHub.type = rssFeed.cloud?.attributes?.protocolSpecification
                newFeed.hubs = [newHub]
            }
            
            // Authors support
            if let webmaster = rssFeed.webMaster {
                if newFeed.authors == [] {
                    newFeed.authors = [JSONFeedAuthor(name: webmaster)]
                } else {
                    newFeed.authors?.append(JSONFeedAuthor(name: webmaster))
                }
            }
            if let managingEditor = rssFeed.managingEditor {
                if newFeed.authors == [] {
                    newFeed.authors = [JSONFeedAuthor(name: managingEditor)]
                } else {
                    newFeed.authors?.append(JSONFeedAuthor(name: managingEditor))
                }
            }
            
            // RSS Feed image
            if rssFeed.image?.height == rssFeed.image?.width {
                newFeed.icon = URL(string: rssFeed.image?.url ?? "")
            }
            
            // RSS Feed items
            for item in rssFeed.items ?? [] {
                var newItem = JSONFeedItem()
                newItem.title = item.title
                newItem.url = URL(string: item.link ?? "")
                
                // match is content text or HTML
                if (item.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isValidHtmlString() {
                    newItem.contentHtml = item.description
                } else {
                    newItem.contentText = item.description
                }
                
                // ID
                newItem.id = item.guid?.value
                
                // Author
                if let author = item.author {
                    newItem.authors = [JSONFeedAuthor(name: author)]
                }
                
                // Date_Published
                newItem.datePublished = item.pubDate
                
                // Enclosure
                if let enclosure = item.enclosure?.attributes {
                    newItem.attachments = [JSONFeedAttachment(url: URL(string: enclosure.url ?? ""), mimeType: enclosure.type, sizeInBytes: enclosure.length == nil ? nil : Int(enclosure.length!))]
                }
                
                // Category
                if let categories = item.categories {
                    newItem.tags = categories.compactMap({ category in
                        category.value
                    })
                }
                
                if newFeed.items == nil {
                    newFeed.items = []
                }
                
                newFeed.items?.append(newItem)
            }
        case .json(let jSONFeed):
            newFeed = jSONFeed
        }
        return newFeed
    }
}


extension Feed {
    public func makeJSONFeed() -> JSONFeed {
        JSONFeed.makeJSONFeed(from: self)
    }
}
