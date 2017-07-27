//
//  ViewController.m
//  IPModelSerializer
//
//  Created by yingwang on 2017/6/30.
//  Copyright © 2017年 GeorgeWang03. All rights reserved.
//

#import "ViewController.h"
#import "WYModelSerialization.h"

@interface ViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (unsafe_unretained) IBOutlet NSTextView *rigionDocumentTextView;
@property (unsafe_unretained) IBOutlet NSTextView *finalDocumentTextView;
@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic, strong) NSArray *models;
@property (nonatomic, strong) NSArray *currentModels;

@property (nonatomic, strong) NSMutableArray *trace;

@end

@implementation ViewController

- (NSArray *)trace {
    if (!_trace) {
        _trace = [NSMutableArray array];
    }
    return _trace;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)handleBackButtonAction:(id)sender {
    
    if (self.trace.count) {
        self.currentModels = [self.trace lastObject];
        [self.trace removeLastObject];
        [self.tableView reloadData];
        self.finalDocumentTextView.string = @"";
    }
}

- (IBAction)handleSerializeButtonAction:(id)sender {
    
    NSString *rigionString = self.rigionDocumentTextView.string;
    if (!rigionString.length) {
        self.finalDocumentTextView.string = @"XML文档不能为空，请重新输入";
        return;
    }
    
    [WYModelSerialization modelPropertyListFromXMLTextString:rigionString
                                                    complete:^(id obj, BOOL success, NSError *error) {
                                                        if (success) {
                                                            self.models = obj;
                                                            self.currentModels = obj;
                                                            [self.tableView reloadData];
                                                        } else {
                                                            self.finalDocumentTextView.string = @"XML文档格式有误，请重新输入";
                                                        }
                                                    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.currentModels.count;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger selectedRow = [self.tableView selectedRow];
    NSDictionary *nodeInfo = self.currentModels[selectedRow];
    NSArray *properties = nodeInfo[kWYModelSerializationSubpropertyArrayKey];
    
    if (properties.count) {
        
        [self.trace addObject:self.currentModels];
        
        self.currentModels = properties;
        [self.tableView reloadData];
        
        self.finalDocumentTextView.string = nodeInfo[kWYModelSerializationPropertyTextKey];
    }
    
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    NSDictionary *nodeInfo = self.currentModels[row];
    
    if ([tableColumn.identifier isEqualToString:@"Column"]) {
        
        cellView.textField.stringValue = [nodeInfo[kWYModelSerializationNameKey] stringByAppendingFormat:@"     %@", nodeInfo[kWYModelSerializationRemarkKey]];
    }
    
    return cellView;
}

@end
