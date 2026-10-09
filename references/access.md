# BigQuery 与 PubMed 连接预检

## BigQuery

优先复用现有 `bq` / `gcloud`，不为已有 CLI 额外安装 Python 客户端。检查活动登录、配置项目及用户指定的数据集；ADC 文件存在不等于凭据有效，而且 CLI 登录与 ADC 是两套配置，不可混为一谈。

1. 检测 `bq`、`gcloud` 是否存在；用 `gcloud auth list --filter=status:ACTIVE` 检查活动身份，用 `gcloud config get-value project` 检查现有项目。不要打印 token、凭据文件内容或不必要的账号信息。
2. 缺少配置时询问：用于创建查询任务/计费的 project ID、实际数据集及版本、location、身份方式、每次查询扫描字节上限。优先复用获 PhysioNet 授权的用户登录；登录需用户自行完成，不能把服务账号身份自动当成该用户的 MIMIC 授权。
3. CLI 缺登录时指导在终端执行 `gcloud auth login`；只有选择客户端/ADC 方式时才需要 `gcloud auth application-default login`。已有服务账号配置可以核查本地凭据路径，但不让用户粘贴 JSON 私钥，不擅自创建或分发密钥。
4. 使用 `bq ls` / `bq show` 验证实际数据集和表元数据；列表可见不代表能读取表。对已核验表执行 `bq --project_id=<任务项目> query --use_legacy_sql=false --dry_run '<只读 SQL>'`，需要时明确 location。记录 dry run 成功/失败及估计字节，不能称为已完成样本量审计。
5. 明确查询预算后，在实际查询中设置 `--maximum_bytes_billed=<字节上限>`，不指定永久 destination table。未确认预算时停在元数据/dry run，继续文献与设计审计，不执行扫描数据的查询。

区分登录过期、表访问被拒、项目缺少创建任务权限、API 未启用、location 不匹配和预算不足，按真实错误修复；不把所有失败都归为缺少私钥。记录验证时间、任务项目、数据集、身份方式、location、测试类型和结果，不记录秘密。项目/身份变化后重新预检，不把创建 skill 时的环境硬编码给未来用户。

官方：[BigQuery 身份认证](https://docs.cloud.google.com/bigquery/docs/authentication)。

## PubMed

检测环境变量 `NCBI_API_KEY`（兼容 `PUBMED_API_KEY`）和 `NCBI_EMAIL`，只输出是否配置，不输出值。已有配置直接做真实 ESearch 测试；后续通过 ESummary/EFetch 核验记录与摘要。没有 key 仍可低速调用公共 E-utilities，key 用于提高允许请求速率，不是全文订阅权限。

API 请求优先 POST 到 `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi`，参数包含 `db=pubmed`、`term`、`retmode=json`、`retmax`、`tool`，以及已配置的 `api_key`/`email`。用程序从环境读取，不把 key 插入命令行、输出 URL 或异常日志。缺 key 且用户希望配置时，请其通过本地环境/凭据管理设置，不在聊天中索要值。

最低连接测试：用公开术语检索一条记录，验证 HTTP 和 API 错误、返回格式及 PMID；API 返回错误时不能因为 HTTP 200 就宣布成功。记录测试词、日期、结果和是否使用 key。默认限制为无 key 每秒不超过 3 次、有 key 每秒不超过 10 次；共享 key/IP 的其他程序也占用额度，实际使用核对当前官方限制，遇 429 放慢并有限重试。

正式草案检索采用草案中的临床词，执行分页/去重并保留真实搜索记录；一次连通性测试不代表文献审查完成。API key 不提供付费全文访问，全文另按用户权限获取。

官方：[NCBI API 说明](https://www.ncbi.nlm.nih.gov/home/develop/api/)；[E-utilities API key 与速率](https://ncbiinsights.ncbi.nlm.nih.gov/2017/11/02/new-api-keys-for-the-e-utilities/)。
