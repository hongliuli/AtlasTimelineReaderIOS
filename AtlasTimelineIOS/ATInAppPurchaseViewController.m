//
//  ATInAppPurchaseViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 6/17/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATInAppPurchaseViewController.h"
#import "ATConstants.h"

#define PURCHASE_PROD_ID @"com.chroniclemap.unlimitedevents"
#define IN_APP_PURCHASED @"IN_APP_PURCHASED"

@interface ATInAppPurchaseViewController ()

@end

@implementation ATInAppPurchaseViewController

UIAlertView *askToPurchase;
UILabel *purchaseStatusLabel;


- (void) processInAppPurchase
{
    askToPurchase = [[UIAlertView alloc]
                     initWithTitle:NSLocalizedString(@"Purchase Full Version",nil)
                     message:NSLocalizedString(@"Free version allows you to store as many as 50 events and unlimited photos, do you want to support us by purchasing unlimited version for USD$2.99 now?",nil)
                     delegate:self
                     cancelButtonTitle:nil
                     otherButtonTitles:@"Yes", @"No", nil];
    //askToPurchase.delegate = self;
    [askToPurchase show];
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == askToPurchase)
    {
        if (buttonIndex == 0)
        {
            NSLog(@"user want to by");
            if ([SKPaymentQueue canMakePayments]) {
                SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:PURCHASE_PROD_ID]];
                request.delegate = self;
                [request start];
            } else {
                UIAlertView *tmp = [[UIAlertView alloc]
                                    initWithTitle:@"Prohibited"
                                    message:@"Parental Control is enabled, cannot make a purchase!"
                                    delegate:self
                                    cancelButtonTitle:nil
                                    otherButtonTitles:@"Ok", nil];
                [tmp show];
            }
        }
        else
        {
            NSLog(@"user deny to by");
        }
    }
}
//callback in inApp Purchase
-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    if (purchaseStatusLabel != nil)
        [purchaseStatusLabel removeFromSuperview];
    SKProduct *validProduct = nil;
    int count = [response.products count];
    if (count>0) {
        validProduct = [response.products objectAtIndex:0];
        SKPayment *payment = [SKPayment paymentWithProductIdentifier:PURCHASE_PROD_ID];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [[SKPaymentQueue defaultQueue] addPayment:payment]; // <-- KA CHING!
    } else {
        UIAlertView *tmp = [[UIAlertView alloc]
                            initWithTitle:@"Not Available"
                            message:@"No products to purchase"
                            delegate:self
                            cancelButtonTitle:nil
                            otherButtonTitles:@"Ok", nil];
        [tmp show];
    }
}
-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        NSString* alertMsg = nil;
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                // show wait view here
                if (purchaseStatusLabel == nil)
                {
                    purchaseStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake([ATConstants screenWidth]/2 - 80, [ATConstants screenHeight] - 30, 160, 60)];
                    purchaseStatusLabel.backgroundColor = [UIColor lightGrayColor];
                    purchaseStatusLabel.textAlignment = NSTextAlignmentCenter;
                    purchaseStatusLabel.text = @"Processing...";
                }
                //[self.mapView addSubview:purchaseStatusLabel];
                break;
            case SKPaymentTransactionStatePurchased:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [purchaseStatusLabel removeFromSuperview];
                alertMsg = @"Purchased, Thanks!";
                [self setPurchasedInLocal];
                
                break;
            case SKPaymentTransactionStateRestored:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [purchaseStatusLabel removeFromSuperview];
                alertMsg = NSLocalizedString(@"The product is restored, no charge is applied",nil);
                [self setPurchasedInLocal];
                break;
                
            case SKPaymentTransactionStateFailed:
                
                if (transaction.error.code != SKErrorPaymentCancelled) {
                    NSLog(@"Error payment cancelled");
                }
                alertMsg = @"Purchased Failed, please try later!";
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [purchaseStatusLabel removeFromSuperview];
                break;
                
            default:
                break;
        }
        if (alertMsg != nil)
        {
            UIAlertView *tmp1 = [[UIAlertView alloc]
                                 initWithTitle:NSLocalizedString(@"Complete",nil)
                                 message:alertMsg
                                 delegate:self
                                 cancelButtonTitle:nil
                                 otherButtonTitles:NSLocalizedString(@"Ok",nil), nil];
            [tmp1 show];
        }
    }
}
- (void)restorePreviousPurchases { //needs account info to be entered
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self]; //so delegate updateTransactions will be called with SKPaymentTransactionStateRestored
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void) setPurchasedInLocal
{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:@"purchased" forKey:IN_APP_PURCHASED];
}
@end

