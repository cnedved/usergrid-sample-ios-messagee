//
//  LoginViewController.m
//  Messagee
//
//  Created by Ernesto Vargas on 2/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginViewController.h"
#import "UGClient.h"

@implementation LoginViewController

@synthesize scrollView;
@synthesize usernameTextField;
@synthesize passwordTextField;

- (void)authorizeUser:(NSString *)username withPassword:(NSString *)password {
    [[RKClient sharedClient] get:[NSString stringWithFormat:@"%@/token?grant_type=password&username=%@&password=%@", [[UGClient sharedInstance] usergridApp], username, password] delegate:self];
}

- (IBAction)loginButton:(id)sender {
    [self authorizeUser:[usernameTextField text] withPassword:[passwordTextField text]];
    
    if ([[UGClient sharedInstance] isUserLoged]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"tabBarController"];

        [self presentViewController:vc animated:NO completion:nil];
        
    }
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    scrollView.frame = CGRectMake(0, 0, 320, 460);
    [scrollView setContentSize:CGSizeMake(320, 460)];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    [super viewWillAppear:animated];
}

- (void)textFieldDidBeginEditing:(UITextField *)textFieldView {
    currentTextField = textFieldView;
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
    [self.view addGestureRecognizer:gestureRecognizer];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textFieldView {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textFieldView {
    currentTextField = nil;
    [textFieldView resignFirstResponder];
}

- (void)hideKeyboard:(UITapGestureRecognizer *)sender {
    [self.view removeGestureRecognizer:sender];
    //[usernameTextField resignFirstResponder];
    //[passwordTextField resignFirstResponder];
    [currentTextField resignFirstResponder];
}

- (void)keyboardDidShow:(NSNotification *) notification {
    if (keyboardIsShown) return;
    NSDictionary* info = [notification userInfo];
    
    //—-obtain the size of the keyboard—-
    NSValue *aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [self.view convertRect:[aValue CGRectValue] fromView:nil];
    //NSLog(@"%f", keyboardRect.size.height);
    
    //—-resize the scroll view (with keyboard)—-
    CGRect viewFrame = [scrollView frame];
    viewFrame.size.height -= keyboardRect.size.height;
    //viewFrame.size.height -= 25;
    scrollView.frame = viewFrame;
    
    //—-scroll to the current text field—-
    CGRect textFieldRect = [currentTextField frame];
    //NSLog(@"%@", NSStringFromCGRect(textFieldRect));
    [scrollView scrollRectToVisible:textFieldRect animated:YES];
    keyboardIsShown = YES;
}

- (void)keyboardDidHide:(NSNotification *) notification {
    NSDictionary* info = [notification userInfo];
    
    //—-obtain the size of the keyboard—-
    NSValue* aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [self.view convertRect:[aValue CGRectValue] fromView:nil];
    
    //—-resize the scroll view back to the original size (without keyboard)
    CGRect viewFrame = [scrollView frame];
    viewFrame.size.height += keyboardRect.size.height;
    //viewFrame.size.height += 25;
    scrollView.frame = viewFrame;
    keyboardIsShown = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Removes the notifications for keyboard
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
	[super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [self setScrollView:nil];
    [self setUsernameTextField:nil];
    [self setPasswordTextField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)requestDidStartLoad:(RKRequest *)request {
    //NSLog(@"Request start load %@", request.params);
}

- (void)request:(RKRequest *)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    //NSLog(@"Request did send body data");
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    //RKLogCritical(@"Loading of RKRequest %@ completed with status code %d. Response body: %@", request, response.statusCode, [response bodyAsString]);
    //NSLog(@"json: %@", [response parsedBody:nil]);
    
    if ([response isSuccessful]) {
        if ([[response parsedBody:nil] objectForKey:@"access_token"]) {
            [[UGClient sharedInstance] UGClientAccessToken:[[response parsedBody:nil] objectForKey:@"access_token"]];
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"tabBarController"];
            [self presentViewController:vc animated:NO completion:nil];
            
        } else if ([[response parsedBody:nil] objectForKey:@"error"]) {
            UIAlertView* alert = [[UIAlertView alloc]
                                  initWithTitle:nil
                                  message:[[response parsedBody:nil] objectForKey:@"error_description"]
                                  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    } else if ([response isError]) {
        UIAlertView* alert = [[UIAlertView alloc]
                              initWithTitle:@"Error"
                              message:[NSString stringWithFormat:@"Status code: %d", response.statusCode]
                              delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    

}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    NSLog(@"Did Fail Load with error %@", error);
    UIAlertView* alert = [[UIAlertView alloc]
                          initWithTitle:[NSString stringWithFormat:@"Error %d", error.code]
                          message:[NSString stringWithFormat:@"%@", error]
                          delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

-( void)request:(RKRequest *)objectLoaderdidLoadObjects:(NSArray*)objects{
    NSLog(@"Loadedstatuses:%@",objects);
}

#pragma mark RKObjectLoaderDelegate methods
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	//NSLog(@"Loaded object: %@", [objects objectAtIndex:0]);
    
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    NSLog(@"Encountered an error: %@", error);
}

@end
