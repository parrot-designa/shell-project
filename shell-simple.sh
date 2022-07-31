#!/bin/bash
#---------------------------
# 本地编译打包
# 1.检验目录
# 2.校验git信息
# 3.编译前端
# 4.打镜像
# 5.打tag(如果是release)
#---------------------------
#黑色背景 深绿色字体
function black_deepgreen(){ 
    temp=''
    for str in $*
    do 
        result=$(echo "$str" | grep "\[*\]$" ) 
        if [ "$result" != ""  ]
        then 
            temp="$temp\033[40;36;4m${str//\[\*\]/}\033[0m"
        else 
            temp="$temp$str"
        fi
    done
    echo $temp 
}  

function black_green(){ 
    temp=''
    for str in $*
    do 
        result=$(echo "$str" | grep "\[*\]$" ) 
        if [ "$result" != ""  ]
        then 
            temp="$temp\033[40;32;4m${str//\[\*\]/}\033[0m"
        else 
            temp="$temp$str"
        fi
    done
    echo $temp 
}  

function red_black(){ 
    temp=''
    for str in $*
    do 
        result=$(echo "$str" | grep "\[*\]$" ) 
        if [ "$result" != ""  ]
        then 
            temp="$temp\033[41;30;4m${str//\[\*\]/}\033[0m"
        else 
            temp="$temp$str"
        fi
    done
    echo $temp 
}

function yello_red(){ 
    temp=''
    for str in $*
    do 
        result=$(echo "$str" | grep "\[*\]$" ) 
        if [ "$result" != ""  ]
        then 
            temp="$temp\033[43;31;4m${str//\[\*\]/}\033[0m"
        else 
            temp="$temp$str"
        fi
    done
    echo $temp 
} 

# 子项目打包最终目录根目录
path_base=$(pwd)

# portal-front目录
path_portalFront="${path_base}/portal-front"
# saas-admin-front目录
path_saasAdminFront="${path_base}/saas-admin-front"
# app-front目录
path_appFront="${path_base}/app-front"
# saas-front目录
path_container="${path_base}/saas-front"
path_destination="${path_container}/public/child"
path_log="${path_base}/log.md";
# 错误日志
path_error="${path_base}/error.md";
# 公司组件库源版本
npm_registry="http://100.100.142.218:5081/repository/npm-all/"
version="";

pathArray=($path_appFront $path_portalFront $path_saasAdminFront)
#pathArray=($path_appFront) 

divideLine="********************************************************[*]"


checkDestinationDir(){ 
    if [ -d ${path_destination} ]
    then
        black_deepgreen 目录： "${path_destination}[*]" 存在，执行 删除并创建[*] 操作
        rm -r ${path_destination}
    else
        black_deepgreen "目录：${path_destination}不存在，执行创建操作"
    fi
    
    mkdir ${path_destination}
}

checkGitInfo(){
    #查看当前分支
    currentBranch=$(git symbolic-ref --short HEAD)
    black_deepgreen 当前分支是： "${currentBranch}[*]" , 确定在当前分支打镜像？ "(y/n)[*]" 
    read flag
    if [ $flag != y ]
    then    
        red_black 你已经退出！[*]
        exit 0
    fi
    #获取最新的commitid 
    lastCommitId=$(git rev-parse --short HEAD)
    if [ -z $lastCommitId ] 
    then
        red_black 请提交版本！[*]
        exit 0
    fi
    #当前仓库地址
    gitUrl=$(git remote get-url origin)
   
    #使用何种方式https/ssh
    gitMode=$(echo "$gitUrl" | grep "^https:" ) 
    gitModePatten=''
    if [ -n $gitMode ]
    then
        black_deepgreen 你当前git使用的是： https[*]
        gitModePatten=https://git
    else
        black_deepgreen 你当前git使用的是： ssh[*]
        gitModePatten=git@git
    fi  
    # 替换关键词
    gitRepositry=${gitUrl//$gitModePatten/reg}
    # 将冒号替换成/
    gitRepositry=${gitRepositry//://}
    # 将.git删除    %.*：删掉最后一个.以及其右边的字符串
    gitRepositry=${gitRepositry%.git}
    # 保留git仓库名  ##*.：删掉最后一个 .  及其左边的字符串
    gitRepositryName=${gitRepositry##*/} #saas
    
    appName=$gitRepositryName  
}

# 由于项目名和子应用并不对应, 还是得在这里手动映射文件夹
calSubDirPath(){
  buildingSubDir=""; 
  case "$1" in
  $path_portalFront)
    buildingSubDir="${path_destination}/portal"
    ;;
  $path_saasAdminFront)
    buildingSubDir="${path_destination}/admin"
    ;;
  $path_appFront)
    buildingSubDir="${path_destination}/main"
    ;;
  esac 
}


handleProject(){ 
    current_npm_registry=$(npm config get registry)
    if [ $current_npm_registry != $npm_registry ]
    then 
        yello_red "请将npm源地址改为：${npm_registry}否则将无法下载依赖[*]"
        exit 0; 
    fi
    echo $current_npm_registry
    projectPath=$1
    projectName=${projectPath##*/} 
    #安装依赖流程
    black_deepgreen "正在处理：" $projectName[*] "项目"
    echo "" 
    cd $projectPath
    black_deepgreen "当前项目目录为：" $(pwd)[*]  

    #yarn 
    startTime=`date +%Y%m%d-%H:%M:%S`
    startTime_s=`date +%s`
    echo "" 
    yello_red  "开始安装依赖包...[*]"
    echo "" 
    yarn install
    echo "" 
    yello_red  "安装依赖包完成...[*]"
    echo "" 
    endTime=`date +%Y%m%d-%H:%M:%S`
    endTime_s=`date +%s`
    sumTime=$[ $endTime_s - $startTime_s ]
    echo "" 
    black_deepgreen 安装 $projectName[*] 项目依赖包 使用了 $sumTime[*] 秒
    echo "" 
    # yarn build
    echo "" 
    black_deepgreen 当前项目是： "${projectName}[*]" , 是否需要重新打包？ "(y/n)[*]" 
    read flag
    if [ $flag == y ]
    then
    startTime=`date +%Y%m%d-%H:%M:%S`
    startTime_s=`date +%s`
    echo "" 
    yello_red "开始打包...[*]"
    echo "" 
    yarn build
    echo "" 
    yello_red "打包完成...[*]"
    echo "" 
    endTime=`date +%Y%m%d-%H:%M:%S`
    endTime_s=`date +%s`
    sumTime=$[ $endTime_s - $startTime_s ]
    echo "" 
    black_deepgreen 打包 $projectName[*] 项目 使用了 $sumTime[*] 秒
    echo "" 
    else
    echo "" 
    black_deepgreen 当前项目已经是最新，则无需打包
    echo "" 
    fi

    #copy
    calSubDirPath $projectPath 
    cp -r ./build ${buildingSubDir}

    black_deepgreen "$divideLine[*]";
    echo ""
}

function dockerHandle(){
    #当前时间
    currentTime=$(date '+%y%m%d-%H%M')
    tagName=${currentTime}-${lastCommitId}
    appName=${gitRepositry##*/}
    tarName=$appName${tagName}.tar
    imageName=$gitRepositry:${tagName}

    cd $path_container;
    ./docker/dockerbuild.sh push

    #打tar包
    docker save -o "${path_tar}/${tarName}" ${imageName}

    # 写入日志
    echo "# $(date)" >> ${path_log};
    echo "打包时间: ${currentTime}" >> ${path_log};
    echo "打包版本: ${version}" >> ${path_log};
    echo "打包分支: ${currentBranch}" >> ${path_log};
    echo "commitId: ${commitId}" >> ${path_log};
    echo "打包用户: $USER" >> ${path_log};
    echo "远程镜像: ${imageName}" >> ${path_log};
    echo "本地镜像: ${tarName}" >> ${path_log};
    echo -e "\n" >> ${path_log};
    
}



#入口
black_deepgreen "请输入release版本号(如:" v3.4.0[*]  "), 测试包无需输入"
read releaseVersion;
if [ -z $releaseVersion ]
then 
    version=test
    black_deepgreen "测试包" ${version}[*]
else
    version=${releaseVersion}
    black_deepgreen "release包" $version[*]
fi
echo ""
black_green "1.检验文件开始了=================>start[*]"
echo "" 
checkDestinationDir 
echo "" 
black_green "1.检验文件结束了=================>end[*]"
echo "" 
black_green "2.校验git开始了==================>start[*]"
echo "" 
checkGitInfo 
echo "" 
black_green "2.校验git结束了==================>end[*]"
echo "" 
black_green "3.项目编译开始了==================>start[*]"
echo "" 
for path in ${pathArray[@]}
do
    handleProject $path
done
echo "" 
black_green "3.项目编译结束了==================>end[*]"
echo "" 
black_green "4.打镜像开始了==================>start[*]"
echo "" 
dockerHandle
echo "" 
black_green "4.打镜像结束了==================>end[*]"

addTag(){
    if [ $version != "test" ]; then
black_green "5.打镜像开始了==================>start[*]"
        git tag -a ${version} -m \"${version}\"
        git push origin $version;
black_green "5.打镜像结束了==================>end[*]"
    fi
}