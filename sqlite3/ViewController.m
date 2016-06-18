//
//  ViewController.m
//  sqlite3
//
//  Created by zhangbin on 16/6/17.
//  Copyright © 2016年 zhangbin. All rights reserved.
//

#import "ViewController.h"
// 一定要在Build Phases添加libsqlite3.0.tbd，否则程序运行不了，会提示错误
#import <sqlite3.h>
#import "ZBModel.h"

@interface ViewController ()<UITableViewDataSource,UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UITextField *nameL;
@property (weak, nonatomic) IBOutlet UITextField *sightL;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic,assign) sqlite3 *db;
@property(nonatomic,strong)NSMutableArray *models;


@end


@implementation ViewController

-(NSMutableArray *)models{
    if (_models == nil) {
        _models = [NSMutableArray array];
    }
    return _models;
}

- (IBAction)Insert:(id)sender {
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor greenColor];
    // 不写这句代码，数据源方法不会执行，cell也就不会显示
    self.tableView.dataSource = self;
    
    
    // 1.将搜索框添加到tableView的tableHeaderView上
    UISearchBar *searchBar = [[UISearchBar alloc] init];
    searchBar.frame = CGRectMake(0, 0, 280, 50);
    // 让控制器成为UISearchBar的代理
    searchBar.delegate = self;
    self.tableView.tableHeaderView = searchBar;
    
    // 2.初始化数据库
    [self initDataBase];
    
    // 3.查询数据
    [self SearchData];
}

/**
 初始化数据库
 */
-(void)initDataBase{
    // 1.打开数据库(连接数据库）
    NSString *FilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"User.sqlite"];
    NSLog(@"%@",FilePath);
    // 如果数据库文件不存在, 系统会自动创建文件自动初始化数据库,我们无需过问
    // 第一个参数:filename.UTF8String,将OC的字符串转成C语言的字符串
    // 第二个参数:数据库_db的地址(&_db)
    int status = sqlite3_open(FilePath.UTF8String,&_db);
    if (status == SQLITE_OK) { // sqilte3数据库打开成功
        NSLog(@"sqilte3数据库打开成功");
        
        // 2.创建t_User表.由于NOT EXISTS的作用，导致了如果之前存在t_User表，就不创建，如果不存在，就创建一个新的表
        const char *sql = "CREATE TABLE IF NOT EXISTS t_User (id integer PRIMARY KEY,name text NOT NULL, sight real);";
        
        char *errmsg = NULL;
        // 错误信息errmsg的地址(&errmsg)
        sqlite3_exec(self.db,sql,NULL,NULL,&errmsg);
        if (errmsg) {
            NSLog(@"创建表失败%s",errmsg);
        }
    }else{// sqilte3数据打开成功
        NSLog(@"sqilte3数据库打开失败");
    }
}
// 插入数据(既向sqilte3数据库中插入了数据，也向tableView的内容上插入了数据)
- (IBAction)Insert {
    // 向sqilte3数据库中插入数据
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO t_User(name,sight) VALUES ('%@',%f);",self.nameL.text,self.sightL.text.doubleValue];
    sqlite3_exec(self.db, sql.UTF8String, NULL, NULL, NULL);
    // 刷新表格
    ZBModel *model = [[ZBModel alloc] init];
    model.name = self.nameL.text;
    model.sight = self.sightL.text;
    [self.models addObject:model];
    // 向tableView的内容上插入了数据,刷新tableView的内容,
    [self.tableView reloadData];

}

// 查询数据
-(void)SearchData{
    const char *sql = "SELECT name,sight FROM t_User;";
    // stmt是用来取出查询结果的
    sqlite3_stmt *stmt = NULL;
    
    int status = sqlite3_prepare_v2(self.db,sql,-1,&stmt,NULL);
    if (status == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            // 0表示SELECT命令后面的name。根据SELECT命令中出现的name，然后从数据库的t_User表中取出所有的name对应的值,放到等号左边保存
            const char *name = (const char *)sqlite3_column_text(stmt,0);
             // 1表示SELECT后面的sight。根据SELECT命令中出现的sight，然后从数据库的t_User表中取出所有的sight对应的值,放到等号左边保存
            const char *sight = (const char *)sqlite3_column_text(stmt,1);
            
            ZBModel *model = [[ZBModel alloc] init];
        
            // 将c语言的字符串转成OC类型的字符串
            // 注意:千万不要把[NSString alloc]用创建出来的对象string代替，例如 NSString *string = nil;否则char类型的name不显示[已验证]
            // 将数据库中name字段的所有内容放到模型额name属性中存储
            model.name = [[NSString alloc] initWithCString:name encoding:NSUTF8StringEncoding];
            // 将数据库中sight字段的所有内容放到模型额sight属性中存储
            model.sight = [[NSString alloc] initWithCString:sight encoding:NSUTF8StringEncoding];
            // 将模型放到models可变数组中
            [self.models addObject:model];
        }
    }
    
}

#pragma mark - UISearchBarDelegate
// 点击UISearchBar控件就会调用
-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    [self.models removeAllObjects];
    //模糊查询like，只要name中包含searchText关键字，price中包含searchText关键字，满足这两个关键字的cell就会被记录下来，并存入模型，存入数组，然后调用reloadData，执行数据源方法来显示记录下来的cell
    // 两个%%代表一个%
    NSString *sql = [NSString stringWithFormat:@"SELECT name,sight FROM t_User WHERE name LIKE  '%%%@%%' OR sight LIKE '%%%@%%';",searchText,searchText];
    // stmt是用来取出查询结果的
    sqlite3_stmt *stmt = NULL;
    int status = sqlite3_prepare_v2(self.db, sql.UTF8String, -1, &stmt, NULL);
    if (status == SQLITE_OK) {// 准备成功 -- SQL语句正确
        while (sqlite3_step(stmt)==SQLITE_ROW) { // 成功取出一条数据
            // 0表示SELECT命令后面的name
            const char *name = (const char *)sqlite3_column_text(stmt, 0);
            // 1表示SELECT后面的price【已验证】
            const char *sight = (const char *)sqlite3_column_text(stmt, 1);
            ZBModel *model = [[ZBModel alloc] init];
            
            // 将c语言的字符串转成OC类型的字符串
            // 注意:千万不要把[NSString alloc]用创建出来的对象string代替，例如 NSString *string = nil;否则char类型的name不显示[已验证]
            model.name = [[NSString alloc] initWithCString:name encoding:NSUTF8StringEncoding];
            model.sight = [[NSString alloc] initWithCString:sight encoding:NSUTF8StringEncoding];
            [self.models addObject:model];
        }
    
    }
    [self.tableView reloadData];
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSLog(@"%zd",self.models.count);
    return self.models.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *ID = @"User";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID];
        cell.backgroundColor = [UIColor grayColor];
    }
    // 取出indexPath.row这一行的模型，用model保存
    ZBModel *model = self.models[indexPath.row];
    // model模型中有两个属性，只取出model模型中的name属性，然后赋值给这一行cell的textLabel.text属性
    cell.textLabel.text = model.name;
     // model模型中有两个属性，只取出model模型中的sight属性，然后赋值给这一行cell的detailTextLabel.text属性
    cell.detailTextLabel.text = model.sight;
    return cell;
}
@end
