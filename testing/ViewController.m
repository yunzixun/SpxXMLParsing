//
//  ViewController.m
//  testing
//
//  Created by John on 3/11/13.
//  Copyright (c) 2013 ling. All rights reserved.
//

#import "ViewController.h"
#import "DDXML.h"
#import "DDXMLElementAdditions.h"
#import "NSString+DDXML.h"

#define SQLITE_FILE_NAME @"SPXLocal.db"

#define kAttendeeTable @"MD_Attendee"
#define kBrandTable @"MD_Brand"
#define kCategoryTable @"MD_Category"
#define kContentTabTable @"MD_ContentTab"
#define kFeaturedProductTable @"MD_FeaturedProduct"
#define kFileTable @"MD_File"
#define kHotSpotTable @"MD_HotSpot"
#define kIndustryTable @"MD_Industry"
#define kProductTable @"MD_Product"
#define kSubCategoryTable @"MD_SubCategory"
#define kSystemTable @"MD_System"
#define kCategoryProductTable @"MP_Category_Product"
#define kHotSpotCategoryTable @"MP_HotSpot_Category"
#define kIndustryProductTable @"MP_Industry_Product"
#define kHotSpotSubCategoryTable @"MP_HotSpot_SubCategory"
#define kSubCategoryProductTable @"MP_SubCategory_Product"


#define kLibraryCachesPath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kProductXMLPath [kLibraryCachesPath stringByAppendingString:@"/SPX_DATA/productXML/"]
#define kCategoryMapXMLPath [kLibraryCachesPath stringByAppendingString:@"/SPX_DATA/listXML/"]
#define kindustryMapXMLPath [kLibraryCachesPath stringByAppendingString:@"/SPX_DATA/listXML2/"]


#define FLOATEQUAL(x,y) (fabsf(x - y) < 0.000001)

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dbPath = [NSString stringWithFormat:@"%@/%@",[paths objectAtIndex:0],SQLITE_FILE_NAME];
    
    
    
    
    _sharedDB = [[FMDatabase databaseWithPath:dbPath] retain];
    
    if (![_sharedDB open]) {
        exit(0);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_sharedDB close];
    [_sharedDB release];
    [_xmlTextView release];
    [super dealloc];
}



#pragma mark --  parse xml and store database




- (void)clearDatabase
{
    NSArray *tableArray = [[NSArray alloc] initWithObjects:kAttendeeTable,kBrandTable,kCategoryTable,kContentTabTable,kFileTable,kHotSpotTable,kIndustryTable,kProductTable,kSystemTable,kCategoryProductTable,kHotSpotCategoryTable,kIndustryProductTable,kFeaturedProductTable,kSubCategoryTable,kHotSpotSubCategoryTable,kSubCategoryProductTable,nil];
    
    for (NSUInteger i = 0; i < [tableArray count]; i++) {
        NSString *tableName = [tableArray objectAtIndex:i];
        
        NSString *sqlQuery = [NSString stringWithFormat:@"DELETE FROM %@",tableName];
        [_sharedDB executeUpdate:sqlQuery];
        sqlQuery = [NSString stringWithFormat:@"UPDATE sqlite_sequence set seq=0 where name='%@'",tableName];
        [_sharedDB executeUpdate:sqlQuery];
        
    }
    

}


 




- (IBAction)parseXML:(id)sender {
    

    
    
    [self clearDatabase];
    

//    [SVProgressHUD showProgress:_loadingProgress status:_loadingText];
//    
//    [self performSelector:@selector(increaseProgress) withObject:nil afterDelay:0.1];
//    
//    _bIsParsingFinished = NO;
//    
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [self initDataBase]; // 1
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [SVProgressHUD dismiss];
//            [NSObject cancelPreviousPerformRequestsWithTarget:self
//                                                     selector:@selector(increaseProgress)
//                                                       object:nil];
//            
//            _bIsParsingFinished = YES;
//            NSLog(@"The task Finished");
//        });
//    });
    

	HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	
	// Set determinate mode
	HUD.mode = MBProgressHUDModeDeterminate;
    
    HUD.dimBackground = YES;
	
	HUD.delegate = self;
    
    
    [HUD showAnimated:YES whileExecutingBlock:^{
        [self initDataBase];
        HUD.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]] autorelease];
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.labelText = @"Completed";
        sleep(2);
    } completionBlock:^{
        NSLog(@"The task Finished");

        [HUD removeFromSuperview];
        [HUD release];
    }];
	
	
	// myProgressTask uses the HUD instance to update progress
	//[HUD showWhileExecuting:@selector(initDataBase) onTarget:self withObject:nil animated:YES];
}


- (void)initDataBase
{
    // Init Database
    
    [self initBrandDB];
    
    [self initProductDB];
    
    [self updateRelatedProdID];
}



- (void)initBrandDB
{
    
    NSError *error = nil;
    
 
    NSArray  *folderArr = [[NSFileManager defaultManager]  contentsOfDirectoryAtPath:kProductXMLPath error:&error];
    
    
    NSLog(@"the folder count is %d",[folderArr count]);
    
    NSUInteger recordID = 1;
    
    NSMutableString *sqlQuery = [[NSMutableString alloc] initWithString:@""];
    
    for (NSString *folderStr in folderArr) {

        if ([folderStr hasPrefix:@"."])
            continue;
        
        NSLog(@"%@",folderStr);
        
       
        
        
        NSString *insertSQL = [NSString stringWithFormat:@"insert into %@ (ID, Name, SampleProducts, Label) values (%d, '%@', '',''); ",kBrandTable,recordID,folderStr];
        
        [sqlQuery appendString:insertSQL];
        
        recordID++;

    }
    
    [_sharedDB executeBatch:sqlQuery error:&error];
    
    [sqlQuery release];
}


- (void)initProductDB
{
    
    NSError *error = nil;
    
    
    NSArray  *folderArr = [[NSFileManager defaultManager]  contentsOfDirectoryAtPath:kProductXMLPath error:&error];
    
    
    NSUInteger recordID = 1;
    
    NSMutableString *sqlQuery = [[NSMutableString alloc] initWithString:@""];
    
    
    HUD.labelText = @"Initiating";
    
    
    for (NSUInteger i = 0; i < [folderArr count]; i++) {
        
        
        HUD.progress = (1.0f/[folderArr count] * (i+1));
        
        


        
        NSString *folderStr = [folderArr objectAtIndex:i];
        
        if ([folderStr hasPrefix:@"."])
            continue;
        

        
        NSString *productXMLPath = [NSString stringWithFormat:@"%@%@/",kProductXMLPath,folderStr];
        
        NSArray *xmlListArr = [self recursivePathsForResourcesOfType:@"XML" inDirectory:productXMLPath];
        
        
        FMResultSet *rs = [_sharedDB executeQuery:[NSString stringWithFormat:@"select ID from %@ where Name = '%@'",kBrandTable,folderStr]];
        
        
        NSUInteger brandID = 1;
        
        if ([rs next]) {
            brandID = [rs intForColumnIndex:0];
        }


        
        
        //NSLog(@"XML count:%d  files: %@",[xmlListArr count], xmlListArr);
        
        for (NSUInteger i = 0; i < [xmlListArr count]; i++) {
            
            NSString *xmlFilePath = [xmlListArr objectAtIndex:i];
            

 
            
            DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithData:[NSData dataWithContentsOfFile:xmlFilePath] options:0 error:&error];
            
            DDXMLElement *rootElement= [xmlDoc rootElement];
            
            NSString *prodName = [[[rootElement elementForName:@"DisplayName"] stringValue] trimLRSpaces];
            NSString *brandTxt = [[[rootElement elementForName:@"Brand"] stringValue] trimLRSpaces];
            NSString *prodTitle = [NSString stringWithFormat:@"pd-%@",[[[rootElement elementForName:@"Title"] stringValue] trimLRSpaces]];
            
            NSString *SPXUrl = [NSString stringWithFormat:@"/en/%@/%@/",brandTxt,prodTitle];
            
            

            
            NSString *insertSQL = [NSString stringWithFormat:@"insert into %@ (ID, Brand_ID, Name, Label, IsFeatured, ProductType, SPXUrl, RelatedProduct1, RelatedProduct2, RelatedProduct3, RelatedProduct4, RelatedProduct5, RelatedProduct6, RelatedProduct7, RelatedProduct8, RelatedProduct9, RelatedProduct10) values (%d, %d, '%@', '', 'No', 'Filters', '%@', null, null, null, null, null, null, null, null, null, null);",kProductTable,recordID,brandID,prodName,SPXUrl];
            
            [sqlQuery appendString:insertSQL];
            
            recordID++;
            

            
        }
        
 
        
    }
    
    [_sharedDB executeBatch:sqlQuery error:&error];
    
    [sqlQuery release];
    
    
    
}


- (void)updateRelatedProdID
{
    
    NSError *error = nil;
    
    
    NSArray  *folderArr = [[NSFileManager defaultManager]  contentsOfDirectoryAtPath:kProductXMLPath error:&error];
    
    
    NSUInteger recordID = 1;
    
    
   HUD.labelText = @"Updating";
    
    
    
    NSMutableString *sqlQuery = [[NSMutableString alloc] initWithString:@""];
    
    for (NSUInteger i = 0; i < [folderArr count]; i++) {
        
        
        HUD.progress = (1.0f/[folderArr count] * (i+1));
        

        
        NSString *folderStr = [folderArr objectAtIndex:i];
        
        if ([folderStr hasPrefix:@"."])
            continue;
        
        
        
        NSString *productXMLPath = [NSString stringWithFormat:@"%@%@/",kProductXMLPath,folderStr];
        
        NSArray *xmlListArr = [self recursivePathsForResourcesOfType:@"XML" inDirectory:productXMLPath];
        
 
        for (NSUInteger i = 0; i < [xmlListArr count]; i++) {
            
            NSString *xmlFilePath = [xmlListArr objectAtIndex:i];
            
            
            
            
            DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithData:[NSData dataWithContentsOfFile:xmlFilePath] options:0 error:&error];
            
 

            
            NSArray *relatedProductsNodes = [xmlDoc nodesForXPath:@"//RelatedProducts" error:nil];
            
            NSMutableArray *relatedProdsList = [[NSMutableArray alloc] init];
            
            BOOL bFound = NO;
            
            for (DDXMLElement* aElement in relatedProductsNodes) {
                
                if ([[[aElement elementForName:@"h2"] stringValue] isEqualToString:@"RELATED PRODUCTS"]) {
                    NSArray *relatedProds = [aElement elementsForName:@"Product"];
                    
                    for (DDXMLElement* aElement in relatedProds)
                    {
                        [relatedProdsList addObject:[[aElement elementForName:@"h3"] stringValue]];
                    }
                    
                }
            }
            
            NSLog(@"relatedProdsList:%@", relatedProdsList);
            
            NSMutableString *relatedProdSqlString  = [[NSMutableString alloc] initWithString:@""];
            
            for (NSUInteger i = 0; i < [relatedProdsList count]; i++) {

                NSString *prodName = [relatedProdsList objectAtIndex:i];
                
                FMResultSet *rs = [_sharedDB executeQuery:[NSString stringWithFormat:@"select ID from %@ where Name = '%@'",kProductTable,prodName]];
                
                
                NSUInteger productID;
                
                if ([rs next]) {
                    productID = [rs intForColumnIndex:0];
                }
                
                [relatedProdSqlString appendFormat:@"RelatedProduct%d = %d, ",i+1,productID];
                
                bFound = YES;
            
            }
            
            if (bFound) {
        
                
                NSString *updateSQL = [NSString stringWithFormat:@"update %@ set %@ where ID = %d;",kProductTable,[relatedProdSqlString substringToIndex:[relatedProdSqlString length] - 2],recordID];
                
                [sqlQuery appendString:updateSQL];
                
            }
            
            recordID++;
            
            [relatedProdsList release];
            [relatedProdSqlString release];
            
        }
        
        
        
    }
    

    [_sharedDB executeBatch:sqlQuery error:&error];

    [sqlQuery release];
    
    
    
    
    
    
}


#pragma mark -- utilities


- (NSArray *) recursivePathsForResourcesOfType: (NSString *)type inDirectory: (NSString *)directoryPath{
    
    NSMutableArray *filePaths = [[[NSMutableArray alloc] init] autorelease];
    
    // Enumerators are recursive
    NSDirectoryEnumerator *enumerator = [[[NSFileManager defaultManager] enumeratorAtPath:directoryPath] retain] ;
    
    NSString *filePath;
    
    while ( (filePath = [enumerator nextObject] ) != nil ){
        
        // If we have the right type of file, add it to the list
        // Make sure to prepend the directory path
        if( [[[filePath pathExtension] lowercaseString] isEqualToString:[type lowercaseString]] ){
            [filePaths addObject:[directoryPath stringByAppendingString: filePath]];
        }
    }
    
    [enumerator release];
    
    return filePaths;
}


@end
