CREATE DEFINER=`root`@`%` FUNCTION `mobile_en_de_crypt`(`@mobile` char(11),`@type` tinyint) RETURNS char(11) CHARSET utf8
BEGIN
	#手机号加解密
	DECLARE mobile CHAR(11) DEFAULT TRIM(`@mobile`);
	DECLARE type TINYINT DEFAULT CAST(`@type` AS UNSIGNED);
	DECLARE dic_up CHAR(22) DEFAULT 'DPBKFETCSJVRUGMNLIAHOQ';#大小写分开因为locate对此大小写支持性不好，即便已转为二进制处理
	#DECLARE dic_lw CHAR(22) DEFAULT 'gtamdrjpcbnfyewukqvxlh';
	DECLARE dic_fill CHAR(10) DEFAULT '+_X=Z-W[Y]';#32进制中没有WXYZ
	DECLARE front_two TINYINT DEFAULT 0;
	DECLARE fourchar VARCHAR(4) DEFAULT '';
	DECLARE fourcode VARCHAR(4) DEFAULT '';
	DECLARE onechar CHAR(1) DEFAULT '';
	DECLARE i TINYINT DEFAULT 0;
	
	#规则：只加密第4-7位，取出这四位并转为无符号整数。A BC DEFG HJKM  加密如下：BC*DEFG+HJKM，和值转成32进制，不足4为左补0，然后四位中替换数字为填充字符中对应的值。解密反之
	IF(LENGTH(mobile) != 11)THEN
		RETURN "";
	ELSEIF(type = 1)THEN#加密
		SET front_two = CAST(SUBSTR(mobile FROM 2 FOR 2) AS UNSIGNED);
		SET fourchar = CAST(SUBSTR(mobile FROM 4 FOR 4) AS UNSIGNED);
		IF(fourchar < 0 OR fourchar > 9999 OR front_two < 30 OR front_two > 90)THEN
			RETURN "";
		ELSE
			SET fourcode = CONV(front_two*fourchar+CAST(SUBSTR(mobile FROM 8) AS UNSIGNED),10,32);
			WHILE (i < 4) DO
				SET i = i + 1;
				SET @num = LOCATE(SUBSTR(fourcode FROM i FOR 1),'1234567890');
				IF (@num > 0)THEN
					SET fourcode = CONCAT(SUBSTR(fourcode FROM 1 FOR i - 1),SUBSTR(dic_fill FROM @num FOR 1),SUBSTR(fourcode FROM i + 1));
				END IF;				
			END WHILE;
			RETURN CONCAT(SUBSTR(mobile FROM 1 FOR 3),fourcode,SUBSTR(mobile FROM 8));
		END IF;
	ELSEIF(type = 0)THEN#解密
		SET fourchar = SUBSTR(mobile FROM 4 FOR 4);
		WHILE (i < 4) DO
			SET i = i + 1;
			SET @num = LOCATE(SUBSTR(fourchar FROM i FOR 1),dic_fill);
			IF (@num > 0)THEN
				SET fourchar = CONCAT(SUBSTR(fourchar FROM 1 FOR i - 1),@num,SUBSTR(fourchar FROM i + 1));
			END IF;				
		END WHILE;
		SET @big_int = (CONV(fourchar,32,10) - CAST(SUBSTR(mobile FROM 8) AS UNSIGNED)) / CAST(SUBSTR(mobile FROM 2 FOR 2) AS UNSIGNED);
		RETURN CONCAT(SUBSTR(mobile FROM 1 FOR 3),@big_int,SUBSTR(mobile FROM 8));
	ELSE
		RETURN '';
	END IF;
END