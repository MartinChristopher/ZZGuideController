//
//  ZZGuideItem.swift
//
//  Created by Apple on 2017/5/8.
//

import UIKit

public class ZZGuideItem: NSObject {
    
    public var sourceView: UIView?
    public var rect: CGRect = .zero
    
    public var arrowImage: UIImage?
    public var text: String!
    
    public init(sourceView: UIView, arrowImage: UIImage? = nil, text: String) {
        self.sourceView = sourceView
        self.arrowImage = arrowImage
        self.text = text
    }
    
    public init(rect: CGRect, arrowImage: UIImage? = nil, text: String) {
        self.rect = rect
        self.arrowImage = arrowImage
        self.text = text
    }
    
}
