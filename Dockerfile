FROM odoo:18.0

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3-venv \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN python3 -m venv /opt/odoo-extra --system-site-packages \
    && /opt/odoo-extra/bin/pip install --no-cache-dir -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

ENV PYTHONPATH=/opt/odoo-extra/lib/python3.12/site-packages

COPY docker/odoo.conf /etc/odoo/odoo.conf
COPY docker/entrypoint.sh /entrypoint-dev.sh
RUN chmod 755 /entrypoint-dev.sh \
    && chown odoo /etc/odoo/odoo.conf /entrypoint-dev.sh

USER odoo
ENTRYPOINT ["/entrypoint-dev.sh"]
