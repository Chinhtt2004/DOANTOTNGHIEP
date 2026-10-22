"""Generate JPA persistence scaffolding from this repository's MySQL schema."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'src/main/java/com/roomrental'
SQL = (ROOT / 'schema.mysql.sql').read_text(encoding='utf-8')

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')

def pascal(value):
    return ''.join(x.capitalize() for x in value.split('_'))

def camel(value):
    value = pascal(value)
    return value[0].lower() + value[1:]

def singular(value):
    return {'lifestyle_criteria': 'lifestyle_criterion'}.get(value, value[:-3] + 'y' if value.endswith('ies') else value[:-1] if value.endswith('s') else value)

tables = re.findall(r'CREATE TABLE `([^`]+)` \((.*?)\) ENGINE=', SQL, re.S)
assert len(tables) == 42
manifest = []
for table, body in tables:
    name = pascal(singular(table))
    fields, methods, lifecycle = [], [], []
    columns = re.findall(r'^  `([^`]+)` ([A-Z]+)(\([^\n]*?\))?([^\n]*)', body, re.M)
    for col, sql_type, args, rest in columns:
        generated = 'GENERATED ALWAYS' in rest
        field = camel(col)
        typ = {'BIGINT':'Long', 'INT':'Integer', 'TINYINT':'Byte', 'BOOLEAN':'Boolean', 'DATE':'LocalDate', 'DATETIME':'LocalDateTime', 'DECIMAL':'BigDecimal', 'JSON':'JsonNode', 'VARCHAR':'String', 'CHAR':'String', 'TEXT':'String', 'LONGTEXT':'String'}[sql_type]
        annotations = []
        if col == 'id':
            annotations.append('    @Id')
            if 'AUTO_INCREMENT' in rest:
                annotations.append('    @GeneratedValue(strategy = GenerationType.IDENTITY)')
        if sql_type == 'JSON':
            annotations.append('    @JdbcTypeCode(SqlTypes.JSON)')
        attrs = [f'name = "`{col}`"', f'nullable = {str("NOT NULL" not in rest).lower()}']
        if sql_type in ('VARCHAR', 'CHAR'):
            attrs.append(f'length = {args[1:-1]}')
        if sql_type == 'DECIMAL':
            precision, scale = args[1:-1].split(',')
            attrs.extend([f'precision = {precision}', f'scale = {scale}'])
        if sql_type in ('TEXT', 'LONGTEXT', 'JSON', 'CHAR', 'DATETIME', 'TINYINT'):
            attrs.append(f'columnDefinition = "{sql_type}{args}"')
        if generated:
            attrs.extend(['insertable = false', 'updatable = false'])
        if col == 'created_at':
            attrs.append('updatable = false')
        annotations.append('    @Column(' + ', '.join(attrs) + ')')
        default = re.search(r"DEFAULT ('[^']*'|TRUE|FALSE|-?\d+(?:\.\d+)?)", rest)
        initializer = ''
        if default and not generated:
            val = default[1]
            if typ == 'String': val = '"' + val[1:-1] + '"'
            elif typ == 'Boolean': val = val.lower()
            elif typ == 'Long': val += 'L'
            elif typ == 'BigDecimal': val = f'new BigDecimal("{val}")'
            initializer = ' = ' + val
        fields.append('\n'.join(annotations) + f'\n    private {typ} {field}{initializer};')
        methods.append(f'    public {typ} get{pascal(col)}() {{ return {field}; }}')
        if not generated and col not in ('created_at', 'updated_at'):
            methods.append(f'    public void set{pascal(col)}({typ} {field}) {{ this.{field} = {field}; }}')
    has_audit = any(c[0] == 'created_at' for c in columns)
    audit = '''
    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now(ZoneOffset.UTC);
    }
''' if has_audit else ''
    write(BASE / f'entity/{name}.java', f'''package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps {table}. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "{table}")
public class {name} implements IdentifiedEntity {{
{chr(10).join(fields)}

{chr(10).join(methods)}
{audit}}}
''')
    write(BASE / f'repository/{name}Repository.java', f'''package com.roomrental.repository;

import com.roomrental.entity.{name};
import org.springframework.data.jpa.repository.JpaRepository;

public interface {name}Repository extends JpaRepository<{name}, Long> {{
}}
''')
    write(BASE / f'service/{name}Service.java', f'''package com.roomrental.service;

import com.roomrental.entity.{name};
import com.roomrental.repository.{name}Repository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class {name}Service extends BaseService<{name}> {{
    public {name}Service({name}Repository repository, EntityManager entityManager) {{
        super(repository, entityManager, {name}.class, {str(table in ('tenants','landlords','admins')).lower()});
    }}
}}
''')
    manifest.append(f'| `{table}` | `{name}` | {len(columns)} |')
write(ROOT / 'docs/entity-mapping.md', '# Ánh xạ schema\n\nKhóa ngoại giữ dưới dạng ID, kể cả khóa ngoại ghép. MySQL kiểm tra các ràng buộc từ schema gốc. Các cột generated chỉ đọc.\n\n| Bảng | Entity | Số cột |\n| --- | --- | --- |\n' + '\n'.join(manifest) + '\n')
print(f'Generated {len(tables)} entities, repositories and services.')
