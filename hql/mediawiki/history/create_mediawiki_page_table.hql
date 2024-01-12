-- Creates table statement for raw mediawiki_page table.
--
-- Parameters:
--     <none>
--
-- Usage
--     hive -f create_mediawiki_page_table.hql \
--         --database wmf_raw
--

CREATE EXTERNAL TABLE `mediawiki_page`(
  `page_id`             bigint      COMMENT 'Uniquely identifying primary key along with wiki. This value is preserved across edits, renames, and, as of MediaWiki 1.27, deletions, via an analogous field in the archive table (introduced in MediaWiki 1.11). For example, for this page, page_id = 10501. [1][2] This field can be accessed by WikiPage::getId(), Title::getArticleID(), etc.',
  `page_namespace`      int         COMMENT 'A page name is broken into a namespace and a title. The namespace keys are UI-language-independent constants, defined in includes/Defines.php.  This field contains the number of the page\'s namespace. The values range from 0 to 15 for the standard namespaces, and from 100 to 2147483647 for custom namespaces.',
  `page_title`          string      COMMENT 'The sanitized page title, without the namespace, with a maximum of 255 characters (binary). It is stored as text, with spaces replaced by underscores. The real title shown in articles is just this title with underscores (_) converted to spaces ( ). For example, a page titled "Talk:Foo Bar" would have "Foo_Bar" in this field.',
  `page_is_redirect`    boolean     COMMENT 'A value of 1 here indicates the article is a redirect\; it is 0 in all other cases.',
  `page_is_new`         boolean     COMMENT 'This field stores whether the page is a new, meaning it either has only one revision or has not been edited since being restored, even if there is more than one revision. If the field contains a value of 1, then it indicates that the page is a new\; otherwise, it is 0. Rollback links are not displayed if the page is new, since there is nothing to roll back to.',
  `page_random`         double      COMMENT 'Random decimal value, between 0 and 1, used for Special:Random (see Manual:Random page for more details). Generated by wfRandom().',
  `page_touched`        string      COMMENT 'This timestamp is updated whenever the page changes in a way requiring it to be re-rendered, invalidating caches. Aside from editing this includes permission changes, creation or deletion of linked pages, and alteration of contained templates. Set to $dbw->timestamp() at the time of page creation.',
  `page_links_updated`  string      COMMENT 'This timestamp is updated whenever a page is re-parsed and it has all the link tracking tables updated for it. This is useful for de-duplicating expensive backlink update jobs. Set to the default value of NULL when the page is created by WikiPage::insertOn().',
  `page_latest`         bigint      COMMENT 'This is a foreign key to rev_id for the current revision. It may be 0 during page creation. It needs to link to a revision with a valid revision.rev_page, or there will be the "The revision #0 of the page named \'Foo\' does not exist" error when one tries to view the page. Can be obtained via WikiPage::getLatest().',
  `page_len`            bigint      COMMENT 'Uncompressed length in bytes of the page\'s current source text.  This however, does not apply to images which still have records in this table. Instead, the uncompressed length in bytes of the description for the file is used as the latter is in the text.old_text field.  The Wikipage class in includes/WikiPage.php has two methods, viz., insertOn() and updateRevisionOn() that are responsible for populating these details.',
  `page_content_model`  string      COMMENT 'Content model, see CONTENT_MODEL_XXX constants. Comparable to revision.rev_content_model.'
)
COMMENT
  'See most up to date documentation at https://www.mediawiki.org/wiki/Manual:Page_table'
PARTITIONED BY (
  `snapshot` string COMMENT 'Versioning information to keep multiple datasets (YYYY-MM for regular labs imports)',
  `wiki_db` string COMMENT 'The wiki_db project')
ROW FORMAT SERDE
  'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
STORED AS INPUTFORMAT
  'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
LOCATION
  'hdfs://analytics-hadoop/wmf/data/raw/mediawiki/tables/page'
;
