//
//  QBScrollViewController.m
//  QBFramework
//
//  Created by quentin on 2017/4/11.
//  Copyright © 2017年 quentin. All rights reserved.
//

#import "QBScrollViewController.h"
#import "QBListTableViewCell.h"
#import "UILabel+Util.h"
#import "UIButton+Util.h"
#import "QBServerRequest.h"
#import "QBScrollItem.h"

// 滚动通知
NSString * const kCellScrollViewNotification = @"kCellScrollViewNotification";

static NSString * offsetX_Key = @"offsetX";


// cell

#define kAvatarSize 50

@interface QBScrollCell : UITableViewCell <UIScrollViewDelegate>

{
    UIButton               *_avatarBtn;// 头像
    UIImageView            *_newsImageView;// 新消息
    
    UILabel                *_nicknameLabel;// 名字
    UILabel                *_orgNameLabel;// 公司
    UILabel                *_countLabel;// 个数
    UILabel                *_companySizeLabel;// 规模
    UILabel                *_voteRightLabel;// 投票权
    UILabel                *_positionLabel;// 职位
    
    UIScrollView           *_bgContentScrollView;
    
    BOOL                    _scrollNotification;
    
    UIView                 *_bottomLineView;
}

@property (nonatomic, strong) QBScrolViewItem *item;
@property (nonatomic, strong) UIScrollView  *bgContentScrollView;

@end

@implementation QBScrollCell
@synthesize bgContentScrollView = _bgContentScrollView;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    // bg scroll view
    _bgContentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, __ksScreenWidth, [QBScrollCell heightWithModel:nil])];
    _bgContentScrollView.showsVerticalScrollIndicator = NO;
    _bgContentScrollView.showsHorizontalScrollIndicator = NO;
    _bgContentScrollView.delegate = self;
    [self.contentView addSubview:_bgContentScrollView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelectRow)];
    [_bgContentScrollView addGestureRecognizer:tapGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cellScrollViewNotification:) name:kCellScrollViewNotification object:nil];
    
    // bottom line
    _bottomLineView = [[UIView alloc] init];
    _bottomLineView.layer.backgroundColor = colorFromRGB(0xd7d7d7).CGColor;
    [_bgContentScrollView addSubview:_bottomLineView];
    
    // avatar
    _avatarBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _avatarBtn.layer.cornerRadius = kAvatarSize / 2;
    _avatarBtn.layer.masksToBounds = YES;
    [_avatarBtn addTarget:self action:@selector(onTapClick:) forControlEvents:UIControlEventTouchUpInside];
    [_bgContentScrollView addSubview:_avatarBtn];
    
    // news
    _newsImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"redPot"]];
    [_bgContentScrollView addSubview:_newsImageView];
    
    // name
    _nicknameLabel = [UILabel initWithFont:[UIFont systemFontOfSize:15] textColor:colorFromRGB(0x131313)];
    [_bgContentScrollView addSubview:_nicknameLabel];
    
    // org name
    _orgNameLabel = [UILabel initWithFont:[UIFont systemFontOfSize:14] textColor:colorFromRGB(0x131313)];
    [_bgContentScrollView addSubview:_orgNameLabel];
    
    // count
    _countLabel = [UILabel initWithFont:[UIFont systemFontOfSize:14] textColor:colorFromRGB(0x131313)];
    _countLabel.textAlignment = NSTextAlignmentCenter;
    [_bgContentScrollView addSubview:_countLabel];
    
    // company size
    _companySizeLabel = [UILabel initWithFont:[UIFont systemFontOfSize:14] textColor:colorFromRGB(0x131313)];
    _companySizeLabel.textAlignment = NSTextAlignmentCenter;
    [_bgContentScrollView addSubview:_companySizeLabel];
    
    // voteRight
    _voteRightLabel = [UILabel initWithFont:[UIFont systemFontOfSize:14] textColor:colorFromRGB(0x131313)];
    _voteRightLabel.textAlignment = NSTextAlignmentCenter;
    [_bgContentScrollView addSubview:_voteRightLabel];
    
    // position
    _positionLabel = [UILabel initWithFont:[UIFont systemFontOfSize:14] textColor:colorFromRGB(0x131313)];
    _positionLabel.textAlignment = NSTextAlignmentCenter;
    [_bgContentScrollView addSubview:_positionLabel];
}

- (void)onTapClick:(id)sender
{
    [self jumpingUserWithUid:_item.authorCode];
}

- (void)didSelectRow
{
    [self jumpingChatViewCtrl:ChatType_Person chatId:_item.authorCode chatName:_item.authorName];
    
    _item.messageState = 0;
    
    [self setNeedsLayout];
}

- (void)setItem:(QBScrollItem *)item
{
    _item = item;
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [_avatarBtn sr_setImageWithURL:[NSURL URLWithString:_item.authorHeadImgUrl] forState:UIControlStateNormal placeholderImage:kAvatarDefaultImage];
    
    _newsImageView.hidden = !_item.messageState;
    _nicknameLabel.text = _item.authorName;
    _orgNameLabel.text = _item.orgName;
    _countLabel.text = [NSString stringWithFormat:@"%@只", @(_item.count)];
    _positionLabel.text = _item.position;
    _companySizeLabel.text = _item.companySize;
    _voteRightLabel.text = _item.voteRight ? @"是" : @"否";
    
    [_nicknameLabel sizeToFit];
    [_orgNameLabel sizeToFit];
    [_countLabel sizeToFit];
    [_newsImageView sizeToFit];
    [_companySizeLabel sizeToFit];
    [_positionLabel sizeToFit];
    [_voteRightLabel sizeToFit];
    
    CGFloat x = 0, y = 0;
    CGFloat width = 150;
    
    // avatar
    x = 15;
    y = (CGRectGetHeight(self.frame) - kAvatarSize) / 2;
    _avatarBtn.frame = CGRectMake(x, y, kAvatarSize, kAvatarSize);
    
    // news
    _newsImageView.frame = CGRectMake(x + kAvatarSize, y, CGRectGetWidth(_newsImageView.frame), CGRectGetHeight(_newsImageView.frame));
    
    // name
    x = CGRectGetMaxX(_avatarBtn.frame) + 10;
    y = (CGRectGetHeight(self.frame) - CGRectGetHeight(_nicknameLabel.frame) - CGRectGetHeight(_orgNameLabel.frame) - 7) / 2;
    _nicknameLabel.frame = CGRectMake(x, y, width - x, CGRectGetHeight(_nicknameLabel.frame));
    
    // org name
    y = CGRectGetMaxY(_nicknameLabel.frame) + 7;
    _orgNameLabel.frame = CGRectMake(x, y, width - x, CGRectGetHeight(_orgNameLabel.frame));
    
    // company size
    x = CGRectGetMaxX(_orgNameLabel.frame);
    y = 0;
    width = 80;
    _companySizeLabel.frame = CGRectMake(x, y, width, CGRectGetHeight(self.frame));
    
    // position
    x = CGRectGetMaxX(_companySizeLabel.frame);
    _positionLabel.frame = CGRectMake(x, y, width, CGRectGetHeight(self.frame));
    
    // vote right
    x = CGRectGetMaxX(_positionLabel.frame);
    width = 110;
    _voteRightLabel.frame = CGRectMake(x, y, width, CGRectGetHeight(self.frame));
    
    // count
    x = CGRectGetMaxX(_voteRightLabel.frame);
    width = 80;
    _countLabel.frame = CGRectMake(x, y, width, CGRectGetHeight(self.frame));
    
    // bg
    _bgContentScrollView.contentSize = CGSizeMake(CGRectGetMaxX(_countLabel.frame), CGRectGetHeight(self.frame));
    
    // bottom line
    x = CGRectGetMinX(_avatarBtn.frame);
    y = CGRectGetHeight(self.frame) - 1;
    _bottomLineView.frame = CGRectMake(x, y, _bgContentScrollView.contentSize.width * 2, 1);
}

+ (CGFloat)heightWithModel:(QBModel *)model
{
    return 75;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    return YES;
}

#pragma mark - notification

- (void)cellScrollViewNotification:(NSNotification *)notification
{
    id object = notification.object;
    NSDictionary *userInfo = notification.userInfo;
    
    if (object != self) {
        
        _scrollNotification = YES;
        
        CGFloat offsetX = [[userInfo objectForKey:offsetX_Key] floatValue];
        _bgContentScrollView.contentOffset = CGPointMake(offsetX, 0);
    }
    else {
        _scrollNotification = NO;
    }
}

#pragma mark - uiscrollview delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _scrollNotification = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollViewEndScrollView:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self scrollViewEndScrollView:scrollView];
}

- (void)scrollViewEndScrollView:(UIScrollView *)scrollView
{
    if (!_scrollNotification) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kCellScrollViewNotification object:self userInfo:@{offsetX_Key : @(scrollView.contentOffset.x)}];
    }
    _scrollNotification = NO;
}

@end

// 视图

@interface QBScrollViewController ()

{
    CGFloat                     _lastCellOffsetX;// 最后cell移动位置
    QBScrollCell   *_cell;
    
    UIScrollView                *_headerScrollView;
}

@end

@implementation QBScrollViewController

- (instancetype)init
{
    if (self = [super initWithURL:@"" parameters:@{@"type" : @(2)} classNameOfCell:NSStringFromClass([QBScrollCell class]) classNameOfModel:NSStringFromClass([QBScrollItem class])]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.viewName = @"滚动Cell";

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cellScrollViewNotification:) name:kCellScrollViewNotification object:nil];
}

#pragma mark - notification

- (void)cellScrollViewNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    id object = notification.object;
    
    _lastCellOffsetX = [[userInfo objectForKey:offsetX_Key] floatValue];
    
    // header title scroll
    CGPoint offset = _headerScrollView.contentOffset;
    offset.x = _lastCellOffsetX;
    _headerScrollView.contentOffset = offset;
    
    object = nil;
}

#pragma mark - uiscroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:self.tableView]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kCellScrollViewNotification object:self userInfo:@{offsetX_Key : @(_lastCellOffsetX)}];
    }

    if ([scrollView isEqual:_headerScrollView]) {
        CGPoint offset = _cell.bgContentScrollView.contentOffset;
        offset.x = scrollView.contentOffset.x;
        _cell.bgContentScrollView.contentOffset = offset;
    }
}

#pragma mark - header view

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSArray *items = [self valueForKey:@"items"];
    if ([items count] == 0) {
        return 0.01f;
    }
    
    return kHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSArray *items = [self valueForKey:@"items"];
    if ([items count] == 0) {
        return nil;
    }
    
    static NSString *identifier = @"header View";
    
    UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
    
    if (headerView == nil) {
        headerView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:identifier];
        headerView.contentView.backgroundColor = colorFromRGB(0xececec);

        _headerScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, __ksScreenWidth, kHeaderHeight)];
        _headerScrollView.showsVerticalScrollIndicator = NO;
        _headerScrollView.showsHorizontalScrollIndicator = NO;
        
        NSArray *headerTitles = @[@"", @"规模", @"职位", @"投票权", @"数量"];
        NSArray *titleWidths = @[@150, @80, @80, @110, @80];
        NSArray *titleXs = @[@0, @150, @230, @310, @420];
        [headerTitles enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            UILabel *titleLabel = [UILabel initWithFont:[UIFont systemFontOfSize:15] textColor:colorFromRGB(0x131313)];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.text = [headerTitles objectAtIndex:idx];
            titleLabel.frame = CGRectMake([[titleXs objectAtIndex:idx] floatValue], 0, [[titleWidths objectAtIndex:idx] floatValue], kHeaderHeight);
            [_headerScrollView addSubview:titleLabel];
            
        }];
        _headerScrollView.contentSize = CGSizeMake(_cell.bgContentScrollView.contentSize.width, kHeaderHeight);
        _headerScrollView.delegate = self;
        [headerView addSubview:_headerScrollView];
    }
    
    return headerView;
}

#pragma mark - UITableView

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *items = [self valueForKey:@"items"];
    
    if ([super isLoadMoreViewNeeded] && indexPath.row >= [items count]) {
        return self.loadMoreCell;
    }
    
    if ([super nullData]) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    static NSString *reuseIdentifier = @"cell";
    
    QBScrollCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[QBScrollCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }

    QBScrollItem *item = [items objectAtIndex:indexPath.row];
    cell.item = item;
    _cell = cell;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
