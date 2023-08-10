import { useContext, useState } from 'react'
import { observer } from 'mobx-react-lite'
import Listings from '../components/Listings'
import './home.css'

import Trustlist from '../contexts/Trustlist'

export default observer(() => {
    const app = useContext(Trustlist)
    const [selectedSection, setSelectedSection] = useState('for sale')
    const [selectedCategory, setSelectedCategory] = useState('')

    return (
        <div className="content">
            <div className="sections">
                {app.sections.map((section) =>
                    section === selectedSection ? (
                        <div
                            className="section-item"
                            style={{
                                backgroundColor: 'white',
                                textDecoration: 'underline',
                            }}
                            key={section}
                        >
                            {section}
                        </div>
                    ) : (
                        <div
                            className="section-item"
                            onClick={() => setSelectedSection(section)}
                            key={section}
                        >
                            {section}
                        </div>
                    )
                )}
            </div>

            <div className="categories">
                {app.categoriesBySection
                    .get(selectedSection)
                    .map((category: string) =>
                        category === selectedCategory ? (
                            <div style={{ display: 'flex' }}>
                                <div
                                    className="category-item"
                                    style={{
                                        fontSize: '1.1rem',
                                        textDecoration: 'underline',
                                    }}
                                    key={category}
                                >
                                    {category}
                                </div>
                                <div>
                                    <hr />
                                </div>
                            </div>
                        ) : (
                            <div
                                className="category-item"
                                style={{ color: '#8080ff' }}
                                key={category}
                                onClick={async () => {
                                    setSelectedCategory(category)
                                }}
                            >
                                {category}
                            </div>
                        )
                    )}
            </div>

            <Listings section={selectedSection} category={selectedCategory} />
        </div>
    )
})
