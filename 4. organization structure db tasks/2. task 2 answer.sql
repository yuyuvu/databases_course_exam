-- Решение задач по базе данных "Структура организации"

-- Задача 2.
-- Найти всех сотрудников, подчиняющихся Ивану Иванову с EmployeeID = 1, включая их подчиненных и подчиненных подчиненных,
-- а также самого Ивана Иванова.
-- Для каждого сотрудника вывести EmployeeID, имя, ManagerID, название отдела, название роли,
-- названия проектов через запятую, названия задач через запятую, общее количество задач,
-- общее количество прямых подчиненных, не включая подчиненных их подчиненных.
-- Если проектов или задач нет, тогда NULL.
-- Использовать RECURSIVE.

-- Решение
WITH RECURSIVE employee_hierarchy AS ( -- рекурсивный CTE для построения иерархии подчинения
    SELECT -- первая часть, начинаем с Ивана Иванова, у которого EmployeeID = 1
    EmployeeID, -- идентификатор сотрудника
    e.Name, -- имя сотрудника
    ManagerID, -- идентификатор менеджера
    DepartmentID, -- идентификатор отдела
    RoleID -- идентификатор роли
    FROM employees AS e -- из таблицы сотрудников
    WHERE e.EmployeeID = 1 -- только Иван Иванов

    UNION ALL

    SELECT -- рекурсивная часть, находим подчинённых текущих сотрудников
    e.EmployeeID, -- идентификатор подчинённого
    e.Name, -- имя подчинённого
    e.ManagerID, -- его менеджер
    e.DepartmentID, -- его отдел
    e.RoleID -- его роль
    FROM employees AS e -- из таблицы сотрудников
    JOIN employee_hierarchy AS eh ON e.ManagerID = eh.EmployeeID -- соединяем с предыдущим уровнем по ManagerID
),
subordinates_count AS ( -- CTE, собирающий количество прямых подчинённых для каждого сотрудника
    SELECT -- выбираем
    ManagerID, -- идентификатор менеджера
    COUNT(EmployeeID) AS total_subordinates -- количество его прямых подчинённых
    FROM employees -- из таблицы сотрудников
    GROUP BY ManagerID -- группируем по менеджеру
),
tasks_count AS ( -- CTE, собирающий количество задач для каждого сотрудника
    SELECT -- выбираем
    AssignedTo, -- сотрудник, которому назначена задача
    COUNT(TaskID) AS total_tasks -- количество задач
    FROM tasks -- из таблицы задач
    GROUP BY AssignedTo -- группируем по сотруднику
)

SELECT -- основной запрос, выводим информацию по каждому сотруднику из иерархии
eh.EmployeeID AS EmployeeID, -- идентификатор сотрудника
eh.Name AS EmployeeName, -- имя сотрудника
eh.ManagerID AS ManagerID, -- идентификатор менеджера
d.DepartmentName AS DepartmentName, -- название отдела
r.RoleName AS RoleName, -- название роли
COALESCE( -- объединяем названия проектов через запятую, если проектов нет, тогда NULL
	(
	SELECT STRING_AGG(p.ProjectName, ', ' ORDER BY p.ProjectName) -- агрегация с сортировкой по имени проекта
	FROM projects AS p -- из таблицы проектов
	WHERE p.DepartmentID = eh.DepartmentID -- проект относится к отделу сотрудника
	), NULL
) AS ProjectNames, -- список проектов
COALESCE( -- объединяем названия задач через запятую, если задач нет, тогда NULL
	(
	SELECT STRING_AGG(t.TaskName, ', ' ORDER BY t.TaskID DESC) -- агрегация с сортировкой по идентификатору задачи
	FROM tasks AS t -- из таблицы задач
	WHERE t.AssignedTo = eh.EmployeeID -- задача назначена текущему сотруднику
	), NULL
) AS TaskNames, -- список задач
COALESCE(tc.total_tasks, 0) AS TotalTasks, -- общее количество задач или 0, если нет
COALESCE(sc.total_subordinates, 0) AS TotalSubordinates -- общее количество прямых подчинённых или 0, если их нет

FROM employee_hierarchy AS eh -- из рекурсивного CTE
LEFT JOIN departments AS d ON eh.DepartmentID = d.DepartmentID -- присоединяем отдел (LEFT JOIN на случай NULL в правой таблице)
LEFT JOIN roles AS r ON eh.RoleID = r.RoleID -- присоединяем роль (LEFT JOIN на случай NULL в правой таблице)
LEFT JOIN subordinates_count AS sc ON eh.EmployeeID = sc.ManagerID -- присоединяем количество подчинённых
LEFT JOIN tasks_count AS tc ON eh.EmployeeID = tc.AssignedTo -- присоединяем количество задач
ORDER BY eh.Name; -- сортируем по имени сотрудника

-- Дополнительные комментарии:
-- Рекурсивный CTE employee_hierarchy строит дерево подчинения, начиная с Ивана Иванова (EmployeeID = 1).
-- Первая часть выбирает самого Ивана. Рекурсивная часть выбирает всех сотрудников, у которых ManagerID
-- равен EmployeeID из предыдущего уровня. Таким образом, в результат попадают все подчинённые любого уровня.
-- CTE subordinates_count подсчитывает количество прямых подчинённых для каждого сотрудника (группировка по ManagerID).
-- CTE tasks_count подсчитывает количество задач, назначенных каждому сотруднику (группировка по AssignedTo).
-- Для каждого сотрудника из иерархии получаем название отдела и роли через LEFT JOIN.
-- Проекты определяются по отделу сотрудника (p.DepartmentID = eh.DepartmentID).
-- Используем подзапрос с STRING_AGG для формирования списка проектов через запятую.
-- Задачи определяются по назначению какому-либо сотруднику (t.AssignedTo = eh.EmployeeID).
-- Аналогично используем подзапрос с STRING_AGG, сортируя задачи по TaskID по убыванию, чтобы порядок
-- в выводе соответствовал ожидаемому.
-- COALESCE(sc.total_subordinates, 0) и COALESCE(tc.total_tasks, 0) заменяют NULL на 0 для сотрудников без подчинённых или задач.
-- Сортировка итога осуществляется через ORDER BY eh.Name по алфавиту по имени сотрудника, согласно условию.