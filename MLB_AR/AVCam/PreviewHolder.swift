//
//  PreviewHolder.swift
//  MLB_AR
//
//  Created by Joey Cohen on 4/28/20.
//  Copyright © 2020 Joey Cohen. All rights reserved.
//

import Foundation

struct PreviewHolder: UIViewRepresentable {
    func makeUIView(context: UIViewRepresentableContext<PreviewHolder>) -> PreviewView {
        PreviewView()
    }

    func updateUIView(_ uiView: PreviewView, context: UIViewRepresentableContext<PreviewHolder>) {
    }

    typealias UIViewType = PreviewView
}
