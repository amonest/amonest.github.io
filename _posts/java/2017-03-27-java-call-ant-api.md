---
layout: post
title: 调用Ant API
---

{% highlight java %}
package com.eta02913.antcall;

import org.apache.tools.ant.DirectoryScanner;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.taskdefs.*;
import org.apache.tools.ant.taskdefs.optional.junit.*;
import org.apache.tools.ant.types.FileSet;
import org.apache.tools.ant.types.FilterSet;
import org.apache.tools.ant.types.PatternSet;
import org.apache.tools.ant.types.ZipScanner;
import org.apache.tools.zip.*;
import java.io.File;
import java.io.IOException;
import java.util.Enumeration;

public class AntCallSample {

    //所有的Task都必须设置一个Project对象，可以共用一个Project.
    private Project prj = new Project();

    public void mkDir(String fileName) {
        mkdir(new File(fileName));
    }

    public void mkdir(File file) {
        Mkdir mkdir = new Mkdir();
        mkdir.setProject(prj);
        mkdir.setDir(file);
        mkdir.execute();
    }

    public void deleteDir(String dirPath) {
        deleteDir(new File(dirPath));
    }

    public void deleteDir(File dir) {
        Delete delete = new Delete();
        delete.setProject(prj);
        delete.setDir(dir);
        delete.execute();
    }

    public void deleteFile(File file) {
        Delete delete = new Delete();
        delete.setProject(prj);
        delete.setFile(file);
        delete.execute();
    }

    public void copyFileToDir(File file, File toDir, boolean isOverWrite) {
        Copy copy = new Copy();
        copy.setProject(prj);
        copy.setFile(file);
        copy.setTodir(toDir);
        copy.setOverwrite(isOverWrite);
        copy.execute();
    }

    /**
     * 复制文件并替换文件中的内容
     *
     * @param fromDir  待复制的文件夹
     * @param toDir    目标文件夹
     * @param includes 包含哪些文件
     * @param token    文件中待替换的字符串
     * @param value    替换后的字符串
     */
    public void copyAndReplace(File fromDir, File toDir, String includes, String token, String value) {
        Copy copy = new Copy();
        copy.setEncoding("UTF-8");
        copy.setProject(prj);
        copy.setTodir(toDir);
        FileSet fileSet = new FileSet();
        fileSet.setDir(fromDir);
        fileSet.setIncludes(includes);
        copy.addFileset(fileSet);
        FilterSet filter = copy.createFilterSet();
        filter.addFilter("eosapp_name", "app1");
        copy.execute();
    }

    public void move(File file, File toDir) {
        Copy copy = new Move();
        copy.setProject(prj);
        copy.setFile(file);
        copy.setTodir(toDir);
        copy.execute();
    }

    public void rename(File oldFile, File newFile) {
        Copy copy = new Copy();
        copy.setProject(prj);
        copy.setFile(oldFile);
        copy.setTodir(newFile);
        copy.execute();
    }

    /**
     * 文件集合
     *
     * @param dir
     * @param includes 包含的文件；表达式，使用,或者空格分隔字符串，“**”代表所有文件或目录，“*.*”代表说有文件， “*.java”代表所有扩展名为java的文件
     * @param excludes 排除的文件：表达式，使用,或者空格分隔字符串，“**”代表所有文件或目录，“*.*”代表说有文件， “*.java”代表所有扩展名为java的文件
     */
    public void createFileSet(File dir, String includes, String excludes) {
        FileSet fs = new FileSet();
        fs.setProject(prj);
        fs.setDir(dir);
        if (isEmpty(includes)) {
            includes = "**/*.*";//默认包含所有文件
        }
        fs.setIncludes(includes);

        if (!isEmpty(excludes)) {
            fs.setExcludes(excludes);
        }
    }

    private boolean isEmpty(String str) {
        return str == null || "".equals(str);
    }

    public void scanDir(File baseFile) {
        DirectoryScanner ds = new DirectoryScanner();
        ds.setBasedir(baseFile);
        ds.scan();
        if (ds.getIncludedFilesCount() > 0) {
            String[] includeFiles = ds.getIncludedFiles();
            for (String file : includeFiles) {
                System.out.println(file);
            }
        }
    }

    public void zipFile(FileSet fileSet, File destFile) {
        Zip zip = new Zip();
        zip.setProject(prj);
        zip.setDestFile(destFile);
        zip.addFileset(fileSet);
        zip.execute();
    }

    public void jarFile(FileSet fileSet, File destFile) {
        Jar jar = new Jar();
        jar.setProject(prj);
        jar.setDestFile(destFile);
        jar.addFileset(fileSet);
        jar.execute();
    }

    public void expandAllFile(File srcFile, File destDir, boolean isOverWrite) {
        Expand expand = new Expand();
        expand.setProject(prj);
        expand.setSrc(srcFile);
        expand.setOverwrite(isOverWrite);
        expand.setDest(destDir);
        expand.execute();
    }

    public void expanFileWithPattern(File srcFile, File destDir, PatternSet patternset, boolean isOverWrite) {
        Expand expand = new Expand();
        expand.setProject(prj);
        expand.setSrc(srcFile);
        expand.setOverwrite(isOverWrite);
        expand.setDest(destDir);
        expand.addPatternset(patternset);
        expand.execute();
    }

    public void createPatternSet(String includes, String excludes) {
        PatternSet patternset = new PatternSet();
        patternset.setProject(prj);
        if (!isEmpty(includes)) {
            patternset.setIncludes(includes);
        }
        if (!isEmpty(excludes)) {
            patternset.setExcludes(excludes);
        }
    }

    public void readZipFile(File zipFile) {
        ZipFile zipfile = null;
        try {
            zipfile = new ZipFile(zipFile);
            Enumeration entries = zipfile.getEntries();
            while (entries.hasMoreElements()) {
                ZipEntry entry = (ZipEntry) entries.nextElement();
                if (entry.isDirectory()) {
                    System.out.println("Directory: " + entry.getName());
                } else {
                    System.out.println("file: " + entry.getName());
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (zipfile != null) {
                try {
                    zipfile.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    public void scanZipFile(File srcFile) {
        ZipScanner scan = new ZipScanner();
        scan.setSrc(srcFile);
        //scan.setIncludes(new String[]);
        scan.scan();
        String dirs[] = scan.getIncludedDirectories();
        String files[] = scan.getIncludedFiles();
    }

    public void simpleJunitTest(String testClassName, File reportXmlDir, boolean isFork) throws Exception {
        JUnitTask task = new JUnitTask();
        initJunitTask(isFork, task);
        JUnitTest test = new JUnitTest(testClassName);
        task.addTest(test);
        test.setTodir(reportXmlDir);
        task.execute();
    }

    public void callBatchJunitTest(String includes, boolean isFork, FileSet fs, File reportXmlDir) throws Exception {
        JUnitTask task = new JUnitTask();
        initJunitTask(isFork, task);
        BatchTest btest = task.createBatchTest();
        btest.addFileSet(fs);
        btest.setTodir(reportXmlDir);
        task.execute();
    }

    private void initJunitTask(boolean isFork, JUnitTask task) {
        task.setProject(prj);
        task.setFork(isFork);
        JUnitTask.SummaryAttribute printSummary = new JUnitTask.SummaryAttribute();
        printSummary.setValue("yes");
        task.setPrintsummary(printSummary);
        task.setHaltonerror(false);
        task.setHaltonfailure(false);
        task.setFailureProperty("junit.failure");
        task.setErrorProperty("junit.error");
        task.addFormatter(createFormatterElement("xml"));
    }

    private FormatterElement createFormatterElement(String value) {
        FormatterElement fe = new FormatterElement();
        FormatterElement.TypeAttribute typeAttribute = new FormatterElement.TypeAttribute();
        typeAttribute.setValue(value);
        fe.setType(typeAttribute);
        return fe;
    }

    public void createJunitReport(File reportXmlDir, String tempDir, File reportHtmlDir, File styleDir) throws Exception {
        XMLResultAggregator task = new XMLResultAggregator();
        task.setProject(prj);
        FileSet fs = new FileSet();
        fs.setDir(reportXmlDir);
        fs.setIncludes("TEST-*.xml");
        task.addFileSet(fs);
        task.setTodir(reportXmlDir);

        //必须设置，否则会空指针异常
        prj.setProperty("java.io.tmpdir", tempDir);

        AggregateTransformer aggregateTransformer = task.createReport();
        aggregateTransformer.setTodir(reportHtmlDir);
        AggregateTransformer.Format format = new AggregateTransformer.Format();
        format.setValue(AggregateTransformer.FRAMES);
        aggregateTransformer.setFormat(format);
        aggregateTransformer.setStyledir(styleDir);
        task.execute();
    }
}
{% endhighlight %}