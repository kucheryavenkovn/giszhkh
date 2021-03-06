Функция ПрочитатьТокеныСекреты(ИмяФайла) Экспорт
	ТокеныСекреты = Новый ТаблицаЗначений;
	ТокеныСекреты.Колонки.Добавить("Токен");
	ТокеныСекреты.Колонки.Добавить("Секрет");
	
	ЧтениеТекста = Новый ЧтениеТекста(ИмяФайла, КодировкаТекста.UTF8);
	Строки = ЧтениеТекста.Прочитать();
	КоличествоСтрок = СтрЧислоСтрок(Строки);
	Для н = 1 по КоличествоСтрок Цикл
		Строка = СтрПолучитьСтроку(Строки, н);
		МассивПодстрок = СтрРазделить(Строка, ";");
		ТокенСекрет = ТокеныСекреты.Добавить();
		Для м = 0 По МассивПодстрок.Количество()-1 Цикл
			ТокенСекрет[м]=МассивПодстрок.Получить(м);
		КонецЦикла;
	КонецЦикла;
	ЧтениеТекста.Закрыть();	
	
	//
	КоличествоПопытокОбработки = ТокеныСекреты.Количество();
	ТекущийТокенСекрет = Неопределено;
	Возврат ТокеныСекреты;
КонецФункции

Процедура ПереключитьсяНаСледующийТокен() Экспорт
	Если ТекущийТокенСекрет = Неопределено Тогда
		ТекущийТокенСекрет = Новый Структура("ТекущийНомерСтроки, Токен, Секрет", -1, "", "");
	КонецЕсли;
	ТекущийТокенСекрет.ТекущийНомерСтроки = ТекущийТокенСекрет.ТекущийНомерСтроки + 1;
	КоличествоПопытокОбработки = КоличествоПопытокОбработки - 1;
	Если ТекущийТокенСекрет.ТекущийНомерСтроки  > ТокеныСекреты.Количество()+1 Тогда
		ВызватьИсключение "Закончились токены";
	Иначе
		ЗаполнитьЗначенияСвойств(ТекущийТокенСекрет,ТокеныСекреты[ТекущийТокенСекрет.ТекущийНомерСтроки]);
		
		Сообщить("Изменен токен на "+ТекущийТокенСекрет.Токен + ", количество попыток получания подсказок по вдресу: "+КоличествоПопытокОбработки);
		
	КонецЕсли
КонецПроцедуры


Функция ПолучитьПодсказкиПоАдресу(Адрес, Токен="", Секрет="") Экспорт
	
	Если Токен = "" Тогда
		Токен = ТекущийТокенСекрет.Токен;
		Секрет = ТекущийТокенСекрет.Секрет;
	КонецЕсли;
	
	
	Соединение = Новый HTTPСоединение("suggestions.dadata.ru", 443, , , , 0, Новый ЗащищенноеСоединениеOpenSSL(), Ложь);
	
	//HTTPЗапрос = Новый HTTPЗапрос("/api/v2/clean/address");
	HTTPЗапрос = Новый HTTPЗапрос("suggestions/api/4_1/rs/suggest/address");
	HTTPЗапрос.Заголовки.Вставить( "Content-Type", "application/json" );
	HTTPЗапрос.Заголовки.Вставить( "Accept", "application/json" );
	HTTPЗапрос.Заголовки.Вставить( "Authorization", "Token "+Токен);
	HTTPЗапрос.Заголовки.Вставить("X-Secret"     , Секрет);
	
	
	СтрокаЗапроса = "{ ""query"": " + """" + Адрес + """"+" }";
	//СтрокаЗапроса = "[""" + Адрес + """]";
	HTTPЗапрос.УстановитьТелоИзСтроки(СтрокаЗапроса,КодировкаТекста.UTF8, ИспользованиеByteOrderMark.НеИспользовать);
	HTTPОтвет = Соединение.ОтправитьДляОбработки(HTTPЗапрос);
	A = HTTPОтвет.КодСостояния;
	Ответ = HTTPОтвет.ПолучитьТелоКакСтроку();
	
	Попытка
		ЧтениеJSON = Новый ЧтениеJSON;
		ЧтениеJSON.УстановитьСтроку(	 Ответ );
		Структура = ПрочитатьJSON( ЧтениеJSON );
		ЧтениеJSON.Закрыть();
		Возврат Структура;
	Исключение
		Инфо = ИнформацияОбОшибке();
		ПредставлениеОшибки = ПодробноеПредставлениеОшибки(Инфо);
		Возврат "Ошибка: " +ПредставлениеОшибки;
	КонецПопытки;
	
КонецФункции


Процедура ОбработатьТаблицуЗначений(ТЗ, КоличествоИтераций=Неопределено) Экспорт
	Н = 0;
	Если КоличествоИтераций = Неопределено тогда
		КоличествоИтераций = ТЗ.Количество();
	КонецЕсли;
	
	Если ТЗ.Колонки.Найти("Дадата") = Неопределено Тогда
		ТЗ.Колонки.Добавить("Дадата")
	КонецЕсли;
	
	Индикатор = ирОбщий.ПолучитьИндикаторПроцессаЛкс(КоличествоИтераций, "Обработка");
	
	Для Каждого СтрокаТЧ Из ТЗ Цикл
		Дадата = СтрокаТЧ.Дадата;
		Адрес = СтрокаТЧ.Адрес;
		Если НЕ Дадата = Неопределено Тогда
			Если ТипЗнч(Дадата) = Тип("Структура") Тогда
				ОтветСервиса = Неопределено;
				Если Дадата.Свойство("family", ОтветСервиса) Тогда
					Пока КоличествоПопытокОбработки > 0 Цикл
						
						н = н + 1;
						Дадата = РаботаСДадатаКлиент.ПолучитьПодсказкиПоАдресу(Адрес);
						ирОбщий.ОбработатьИндикаторЛкс(Индикатор);

						Если ОбработатьОтветСервиса(Дадата) Тогда
							СтрокаТЧ.Дадата = Дадата;
							прервать;
						КонецЕсли;
						
						РаботаСДадатаКлиент.ПереключитьсяНаСледующийТокен();
						
						Если Н > КоличествоИтераций Тогда Прервать КонецЕсли;
						
					КонецЦикла;
				КонецЕсли;					
			КонецЕсли;					
		Иначе
			// Строка еще не обработана
			//Прервать;
			Пока КоличествоПопытокОбработки > 0 Цикл
				
				н = н + 1;
				Дадата = РаботаСДадатаКлиент.ПолучитьПодсказкиПоАдресу(Адрес);
				ирОбщий.ОбработатьИндикаторЛкс(Индикатор);
				
				Если ОбработатьОтветСервиса(Дадата) Тогда
					СтрокаТЧ.Дадата = Дадата;
					прервать;
				КонецЕсли;
				
				РаботаСДадатаКлиент.ПереключитьсяНаСледующийТокен();
				
				Если Н > КоличествоИтераций Тогда Прервать КонецЕсли;
				
			КонецЦикла;
				
		КонецЕсли;
		
		Если Н > КоличествоИтераций Тогда Прервать КонецЕсли;
		
	КонецЦикла;
	
	ирОбщий.ОсвободитьИндикаторПроцессаЛкс();
	
КонецПроцедуры

Функция ОбработатьОтветСервиса(Дадата)
	Результат = Ложь;
	Если ТипЗнч(Дадата) = Тип("Структура") Тогда
		ОтветСервиса = Неопределено;
		Если Дадата.Свойство("suggestions", ОтветСервиса) Тогда
			
			Если ТипЗнч(ОтветСервиса) = Тип("Массив") Тогда
				
				Если ОтветСервиса.Количество() = 0 Тогда
					Возврат истина;
				КонецЕсли;
				
				п = ОтветСервиса[0];
				ФИАСДома = п.data.house_fias_id;
				Если ТипЗнч(ФИАСДома) = Тип("Строка") и СтрДлина(ФИАСДома) = 36 Тогда
					// Все хорощо. Осталось только найти нужный дом и квартиру среди списка
					Возврат истина
				КонецЕсли;
				Возврат истина
				
			КонецЕсли;
		ИначеЕсли Дадата.Свойство("family", ОтветСервиса) Тогда
			
			Если ОтветСервиса = "CLIENT_ERROR" Тогда
				
				Причина = Неопределено;
				Если Дадата.Свойство("reason", Причина) и Причина = "Forbidden" Тогда
					Возврат Ложь;
				КонецЕсли;
				
				Если Дадата.Свойство("reason", Причина) и Причина = "Bad Request" Тогда
					Возврат Истина;
				КонецЕсли;
				
			КонецЕсли;
			
			
			// Ошибка. Строка не обработана. Возможно закончился лимит или сервис для учетной записи недоступен
			
			//прервать;
			//Пока КоличествоПопытокОбработки > 0 Цикл
			//	
			//	Дадата = РаботаСДадатаКлиент.ПолучитьПодсказкиПоАдресу(Адрес);
			//							
			//	РаботаСДадатаКлиент.ПереключитьсяНаСледующийТокен();
			//КонецЦикла;
		КонецЕсли;
		
	КонецЕсли;
	
	Возврат Результат;
КонецФункции



